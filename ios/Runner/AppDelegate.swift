import Flutter
import MapKit
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // MKLocalSearchによる店舗名検索 (iOS限定・無料)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "culturetune/local_search",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "search",
          let args = call.arguments as? [String: Any],
          let query = args["query"] as? String
        else {
          result(FlutterMethodNotImplemented)
          return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        // 現在地が渡されていれば周辺を優先
        if let lat = args["lat"] as? Double, let lng = args["lng"] as? Double {
          request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            latitudinalMeters: 20_000,
            longitudinalMeters: 20_000
          )
        }

        MKLocalSearch(request: request).start { response, error in
          if let error = error {
            result(
              FlutterError(
                code: "search_failed", message: error.localizedDescription, details: nil))
            return
          }
          let items: [[String: Any]] = (response?.mapItems ?? []).prefix(15).map { item in
            var address = ""
            if let placemark = item.placemark.title {
              address = placemark
            }
            return [
              "name": item.name ?? "",
              "address": address,
              "lat": item.placemark.coordinate.latitude,
              "lng": item.placemark.coordinate.longitude,
            ]
          }
          result(items)
        }
      }
    }

    // VisionKitによる被写体自動切り抜き (iOS 17+)
    if let controller = window?.rootViewController as? FlutterViewController {
      let cutoutChannel = FlutterMethodChannel(
        name: "culturetune/cutout",
        binaryMessenger: controller.binaryMessenger
      )
      cutoutChannel.setMethodCallHandler { call, result in
        guard call.method == "subject",
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard #available(iOS 17.0, *) else {
          result(FlutterError(code: "unsupported", message: "iOS 17+ required", details: nil))
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          do {
            let url = URL(fileURLWithPath: path)
            let handler = VNImageRequestHandler(url: url)
            let request = VNGenerateForegroundInstanceMaskRequest()
            try handler.perform([request])
            guard let observation = request.results?.first else {
              DispatchQueue.main.async {
                result(FlutterError(code: "no_subject", message: "被写体が見つからない", details: nil))
              }
              return
            }
            let buffer = try observation.generateMaskedImage(
              ofInstances: observation.allInstances,
              from: handler,
              croppedToInstancesExtent: true
            )
            let ciImage = CIImage(cvPixelBuffer: buffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent),
              let data = UIImage(cgImage: cgImage).pngData()
            else {
              DispatchQueue.main.async {
                result(FlutterError(code: "encode_failed", message: "PNG変換に失敗", details: nil))
              }
              return
            }
            let outPath = NSTemporaryDirectory() + "cutout_\(UUID().uuidString).png"
            try data.write(to: URL(fileURLWithPath: outPath))
            DispatchQueue.main.async { result(outPath) }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "cutout_failed", message: error.localizedDescription, details: nil))
            }
          }
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
