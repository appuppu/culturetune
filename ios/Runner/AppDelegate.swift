import CoreBluetooth
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

    // BLEアドバタイズ(レーダー用)。プラグインはpoweredOn前に発信して
    // 失敗するため、電源ONを待ってから発信する自前実装を使う
    if let controller = window?.rootViewController as? FlutterViewController {
      let bleChannel = FlutterMethodChannel(
        name: "culturetune/ble_advertise",
        binaryMessenger: controller.binaryMessenger
      )
      bleAdvertiser.onEvent = { message in
        DispatchQueue.main.async {
          bleChannel.invokeMethod("advState", arguments: message)
        }
      }
      bleChannel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "start":
          guard let args = call.arguments as? [String: Any],
            let name = args["name"] as? String,
            let uuid = args["uuid"] as? String
          else {
            result(FlutterMethodNotImplemented)
            return
          }
          self?.bleAdvertiser.start(name: name, uuid: uuid)
          result(true)
        case "stop":
          self?.bleAdvertiser.stop()
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // BLE転送(シール/シール帳をその場でBluetooth送信)
    if let controller = window?.rootViewController as? FlutterViewController {
      let transferChannel = FlutterMethodChannel(
        name: "culturetune/ble_transfer",
        binaryMessenger: controller.binaryMessenger
      )
      bleTransfer.onEvent = { method, args in
        DispatchQueue.main.async {
          transferChannel.invokeMethod(method, arguments: args)
        }
      }
      transferChannel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "serve":
          guard let args = call.arguments as? [String: Any],
            let name = args["name"] as? String,
            let data = args["data"] as? FlutterStandardTypedData
          else {
            result(FlutterMethodNotImplemented)
            return
          }
          self?.bleTransfer.serve(name: name, data: data.data)
          result(true)
        case "stop":
          self?.bleTransfer.stop()
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private lazy var bleAdvertiser = BleAdvertiser()
  private lazy var bleTransfer = BleTransferPeripheral()
}

/// シール/シール帳のPNGバイト列をGATT通知でストリーム送信するサーバ。
/// META(読み取り)でサイズを伝え、CTRLへの書き込みで送信開始、
/// DATA(通知)へチャンクを流す。
class BleTransferPeripheral: NSObject, CBPeripheralManagerDelegate {
  static let serviceUUID = CBUUID(string: "0000C71F-0000-1000-8000-00805F9B34FB")
  static let metaUUID = CBUUID(string: "0000C720-0000-1000-8000-00805F9B34FB")
  static let dataUUID = CBUUID(string: "0000C721-0000-1000-8000-00805F9B34FB")
  static let ctrlUUID = CBUUID(string: "0000C722-0000-1000-8000-00805F9B34FB")

  private var manager: CBPeripheralManager?
  private var payload = Data()
  private var localName = ""
  private var dataChar: CBMutableCharacteristic?
  private var offset = 0
  private var streaming = false
  private var pendingSetup = false
  private var chunkSize = 100
  var onEvent: ((String, Any?) -> Void)?

  func serve(name: String, data: Data) {
    payload = data
    localName = name
    offset = 0
    streaming = false
    pendingSetup = true
    if manager == nil {
      manager = CBPeripheralManager(delegate: self, queue: nil)
    }
    setupIfReady()
  }

  func stop() {
    streaming = false
    pendingSetup = false
    payload = Data()
    manager?.stopAdvertising()
    manager?.removeAllServices()
  }

  private func setupIfReady() {
    guard let manager, manager.state == .poweredOn, pendingSetup else {
      if let manager, manager.state != .poweredOn, manager.state != .unknown, manager.state != .resetting {
        onEvent?("serveError", "bluetooth state=\(manager.state.rawValue)")
      }
      return
    }
    pendingSetup = false
    manager.stopAdvertising()
    manager.removeAllServices()

    let metaJson = "{\"size\":\(payload.count),\"name\":\"\(localName)\"}"
    let metaChar = CBMutableCharacteristic(
      type: Self.metaUUID, properties: [.read],
      value: metaJson.data(using: .utf8), permissions: [.readable])
    let dChar = CBMutableCharacteristic(
      type: Self.dataUUID, properties: [.notify], value: nil, permissions: [])
    let cChar = CBMutableCharacteristic(
      type: Self.ctrlUUID, properties: [.write, .writeWithoutResponse],
      value: nil, permissions: [.writeable])
    dataChar = dChar

    let service = CBMutableService(type: Self.serviceUUID, primary: true)
    service.characteristics = [metaChar, dChar, cChar]
    manager.add(service)
    manager.startAdvertising([
      CBAdvertisementDataServiceUUIDsKey: [Self.serviceUUID],
      CBAdvertisementDataLocalNameKey: localName,
    ])
    onEvent?("serveReady", nil)
  }

  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    setupIfReady()
  }

  func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    if let error {
      onEvent?("serveError", error.localizedDescription)
    } else {
      onEvent?("serveAdvertising", nil)
    }
  }

  func peripheralManager(
    _ peripheral: CBPeripheralManager, central: CBCentral,
    didSubscribeTo characteristic: CBMutableCharacteristic
  ) {
    chunkSize = max(20, central.maximumUpdateValueLength)
    onEvent?("peerSubscribed", nil)
  }

  func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
    for request in requests where request.characteristic.uuid == Self.ctrlUUID {
      peripheral.respond(to: request, withResult: .success)
      offset = 0
      streaming = true
      pump()
    }
  }

  private func pump() {
    guard streaming, let manager, let dataChar else { return }
    while offset < payload.count {
      let end = min(offset + chunkSize, payload.count)
      let chunk = payload.subdata(in: offset..<end)
      if manager.updateValue(chunk, for: dataChar, onSubscribedCentrals: nil) {
        offset = end
        if offset % (chunkSize * 50) < chunkSize || offset == payload.count {
          onEvent?("sendProgress", ["sent": offset, "total": payload.count])
        }
      } else {
        return  // キューが空くとisReadyで再開される
      }
    }
    streaming = false
    onEvent?("sendDone", nil)
  }

  func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
    pump()
  }
}

/// CBPeripheralManagerがpoweredOnになるのを待ってからアドバタイズする
class BleAdvertiser: NSObject, CBPeripheralManagerDelegate {
  private var manager: CBPeripheralManager?
  private var pending: [String: Any]?
  var onEvent: ((String) -> Void)?

  func start(name: String, uuid: String) {
    pending = [
      CBAdvertisementDataLocalNameKey: name,
      CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: uuid)],
    ]
    if manager == nil {
      manager = CBPeripheralManager(delegate: self, queue: nil)
    }
    advertiseIfReady()
  }

  func stop() {
    pending = nil
    manager?.stopAdvertising()
  }

  private func advertiseIfReady() {
    guard let manager else { return }
    if manager.state != .poweredOn {
      if manager.state != .unknown && manager.state != .resetting {
        onEvent?("state=\(manager.state.rawValue)")
      }
      return
    }
    guard let pending else { return }
    manager.stopAdvertising()
    manager.startAdvertising(pending)
  }

  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    advertiseIfReady()
  }

  func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    if let error {
      onEvent?("error: \(error.localizedDescription)")
    } else {
      onEvent?("ok")
    }
  }
}
