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
      bleAdvertiser.onEvent = { method, args in
        DispatchQueue.main.async {
          bleChannel.invokeMethod(method, arguments: args)
        }
      }
      bleChannel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "approve":
          self?.bleAdvertiser.respond(ok: true)
          result(true)
        case "reject":
          self?.bleAdvertiser.respond(ok: false)
          result(true)
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

/// レーダーの発信+受信ポスト。
/// アドバタイズと同時に「inbox」サービスを公開し、相手(セントラル)からの
/// 書き込みでシール/シール帳のデータを受け取る。
class BleAdvertiser: NSObject, CBPeripheralManagerDelegate {
  static let inboxMetaUUID = CBUUID(string: "0000C723-0000-1000-8000-00805F9B34FB")
  static let inboxDataUUID = CBUUID(string: "0000C724-0000-1000-8000-00805F9B34FB")
  static let inboxRespUUID = CBUUID(string: "0000C725-0000-1000-8000-00805F9B34FB")

  private var manager: CBPeripheralManager?
  private var pending: [String: Any]?
  private var serviceUuid: CBUUID?
  private var serviceAdded = false

  // 受信ポストの状態
  private var expectedSize = 0
  private var senderName = ""
  private var inboxBuffer = Data()
  private var approved = false
  private var respChar: CBMutableCharacteristic?

  var onEvent: ((String, Any?) -> Void)?

  func start(name: String, uuid: String) {
    serviceUuid = CBUUID(string: uuid)
    pending = [
      CBAdvertisementDataLocalNameKey: name,
      CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: uuid)],
    ]
    serviceAdded = false
    if manager == nil {
      manager = CBPeripheralManager(delegate: self, queue: nil)
    }
    advertiseIfReady()
  }

  func stop() {
    pending = nil
    expectedSize = 0
    inboxBuffer = Data()
    manager?.stopAdvertising()
    manager?.removeAllServices()
    serviceAdded = false
  }

  private func advertiseIfReady() {
    guard let manager else { return }
    if manager.state != .poweredOn {
      if manager.state != .unknown && manager.state != .resetting {
        onEvent?("advState", "state=\(manager.state.rawValue)")
      }
      return
    }
    guard let pending, let serviceUuid else { return }
    if !serviceAdded {
      manager.removeAllServices()
      let meta = CBMutableCharacteristic(
        type: Self.inboxMetaUUID, properties: [.write],
        value: nil, permissions: [.writeable])
      let data = CBMutableCharacteristic(
        type: Self.inboxDataUUID, properties: [.write, .writeWithoutResponse],
        value: nil, permissions: [.writeable])
      let resp = CBMutableCharacteristic(
        type: Self.inboxRespUUID, properties: [.notify], value: nil, permissions: [])
      respChar = resp
      let service = CBMutableService(type: serviceUuid, primary: true)
      service.characteristics = [meta, data, resp]
      manager.add(service)
      serviceAdded = true
    }
    manager.stopAdvertising()
    manager.startAdvertising(pending)
  }

  /// 受け取り側の承認/拒否を送信側へ通知する
  func respond(ok: Bool) {
    approved = ok
    if !ok {
      expectedSize = 0
      inboxBuffer = Data()
    }
    if let manager, let respChar {
      manager.updateValue(
        (ok ? "ok" : "no").data(using: .utf8)!, for: respChar,
        onSubscribedCentrals: nil)
    }
  }

  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    advertiseIfReady()
  }

  func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
    if let error {
      onEvent?("advState", "error: \(error.localizedDescription)")
    } else {
      onEvent?("advState", "ok")
    }
  }

  func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
    var needsResponse: CBATTRequest?
    for request in requests {
      needsResponse = request
      guard let value = request.value else { continue }
      if request.characteristic.uuid == Self.inboxMetaUUID {
        // ヘッダ: {"size":n,"name":"..."}
        if let json = try? JSONSerialization.jsonObject(with: value) as? [String: Any] {
          expectedSize = json["size"] as? Int ?? 0
          senderName = json["name"] as? String ?? "ともだち"
          inboxBuffer = Data()
          approved = false
          onEvent?(
            "inboxRequest",
            [
              "name": senderName,
              "size": expectedSize,
              "code": json["code"] as? String ?? "",
            ])
        }
      } else if request.characteristic.uuid == Self.inboxDataUUID {
        guard approved else { continue }
        inboxBuffer.append(value)
        if expectedSize > 0 && inboxBuffer.count >= expectedSize {
          let received = inboxBuffer
          expectedSize = 0
          inboxBuffer = Data()
          approved = false
          onEvent?(
            "inboxData",
            ["name": senderName, "data": FlutterStandardTypedData(bytes: received)])
        }
      }
    }
    if let needsResponse {
      peripheral.respond(to: needsResponse, withResult: .success)
    }
  }
}
