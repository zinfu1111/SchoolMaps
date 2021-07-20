

import UIKit
import MapKit
import CoreLocation
import AVFoundation

enum Direction:String {
    case N = "北"
    case E = "東"
    case S = "南"
    case W = "西"
    case EN = "東北"
    case ES = "東南"
    case WS = "西南"
    case WN = "西北"
    case unowned = "當前"
}

class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {

    @IBOutlet var mapView: MKMapView!
    
    private let userLocationManager = CLLocationManager()
    private var otherPosition:[String:MKPointAnnotation] = [:]
    
    var isOpen = false
    let lang = "zh-TW"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setupData()
        setupMapView()
        setupLocationManager()
        
    }
    
    func setupLocationManager() {
        userLocationManager.delegate = self
        userLocationManager.requestAlwaysAuthorization()
        userLocationManager.startUpdatingLocation()
        
    }
    
    func setupMapView() {
        mapView.delegate = self
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.showsTraffic = true
    }
    
    //設定警車、救護車位置
    func setupData() {
        let objectAnnotation1 = MKPointAnnotation()
        objectAnnotation1.coordinate = CLLocation(latitude: 24.9854889, longitude: 121.5176303).coordinate
        objectAnnotation1.title = "police"
        objectAnnotation1.subtitle =
          "新和國小"

        let objectAnnotation2 = MKPointAnnotation()
        objectAnnotation2.coordinate = CLLocation(latitude: 24.9885223, longitude: 121.5119486).coordinate
        objectAnnotation2.title = "ambulance"
        objectAnnotation2.subtitle =
          "興南夜市"
        otherPosition = ["警車":objectAnnotation1
         ,"救護車":objectAnnotation2]
    }
    
    func refreshPosition(location: CLLocation) {
        
        var showData:[MKPointAnnotation] = []
        let objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = location.coordinate
        objectAnnotation.title = "person"
        objectAnnotation.subtitle =
          "所在位置"
        showData.append(objectAnnotation)
        showData += otherPosition.values
        self.mapView.showAnnotations(showData, animated: true)
        
        var speekerContent = ""
        
        
        //講話時使用
        for item in otherPosition  {
            //距離
            let distance = getDistance(lat1: item.value.coordinate.latitude, lng1: item.value.coordinate.longitude, lat2: location.coordinate.latitude, lng2: location.coordinate.longitude)
            //方位
            let direction = getDirection(target: item.value, current: location).rawValue
            
            if distance < 500 {
                speekerContent += "\(item.key)位於您的\(direction)方約\(Int(distance) ?? 0)公尺"
                print("\(location.coordinate)\(item.key)位於您的\(direction)方約\(distance)公尺")
            }
            
        }
        
        let speechUtterance = AVSpeechUtterance(string: speekerContent)
        speechUtterance.voice = .init(language: "zh-TW")
        speechUtterance.rate = 0.5
        siriSpeaker(data: speechUtterance)
    }
    
    func siriSpeaker(data:AVSpeechUtterance) {
        let speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer.speak(data)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = annotation.title ?? "MyMaker"
        
        guard let identifier = identifier else { return nil }
        
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        var annotationView: MKMarkerAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        annotationView?.markerTintColor = UIColor.clear
        annotationView?.image = UIImage(named: identifier)
        return annotationView
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        
        guard let location = locations.first else { return }
        
        //總縮放範圍
        let range:MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        if !isOpen {
            refreshPosition(location: location)
            isOpen = true
        }
    }
    
    func getDirection(target: MKPointAnnotation, current: CLLocation) -> Direction {
        
        let currentX = current.coordinate.longitude
        let currentY = current.coordinate.latitude
        let targetX = target.coordinate.longitude
        let targetY = target.coordinate.latitude
        
        let resX = Double(targetX-currentX)
        let resY = Double(targetY-currentY)
        
        if resX == 0 && resY > 0 {
            return .N
        }else if resX > 0 && resY > 0 {
            return .EN
        }else if resX > 0 && resY == 0 {
            return .E
        }else if resX > 0 && resY < 0 {
            return .ES
        }else if resX == 0 && resY < 0 {
            return .S
        }else if resX < 0 && resY < 0 {
            return .WS
        }else if resX < 0 && resY == 0 {
            return .W
        }else if resX < 0 && resY > 0 {
            return .WN
        }else{
            return .unowned
        }
    }
}

extension CLLocationManagerDelegate {
    
    //根據角度計算弧度
    func radian(d:Double) -> Double {
         return d * Double.pi/180.0
    }
    //根據弧度計算角度
    func angle(r:Double) -> Double {
         return r * 180/Double.pi
    }
    
    //根據兩點經緯度計算兩點距離(單位：Ｍ)
    func getDistance(lat1:Double,lng1:Double,lat2:Double,lng2:Double) -> Double {
        
        print("getDistance",lat1,lng1,lat2,lng2)
            let EARTH_RADIUS:Double = 6378137.0
        
            let radLat1:Double = self.radian(d: lat1)
            let radLat2:Double = self.radian(d: lat2)
            
            let radLng1:Double = self.radian(d: lng1)
            let radLng2:Double = self.radian(d: lng2)

            let a:Double = radLat1 - radLat2
            let b:Double = radLng1 - radLng2
            
            var s:Double = 2 * asin(sqrt(pow(sin(a/2), 2) + cos(radLat1) * cos(radLat2) * pow(sin(b/2), 2)))
            s = s * EARTH_RADIUS
            return s
    }
}
