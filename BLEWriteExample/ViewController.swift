//
//  ViewController.swift
//  BLEScanExample
//
//  Created by Shuichi Tsutsumi on 2014/12/12.
//  Copyright (c) 2014年 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var statusSW1: UILabel!
    
    @IBOutlet weak var statusR1C1: UILabel!
    @IBOutlet weak var statusR1C2: UILabel!
    @IBOutlet weak var statusR1C3: UILabel!
    @IBOutlet weak var statusR1C4: UILabel!
    
    @IBOutlet weak var statusR2C1: UILabel!
    @IBOutlet weak var statusR2C2: UILabel!
    @IBOutlet weak var statusR2C3: UILabel!
    @IBOutlet weak var statusR2C4: UILabel!
    
    @IBOutlet weak var statusR3C1: UILabel!
    @IBOutlet weak var statusR3C2: UILabel!
    @IBOutlet weak var statusR3C3: UILabel!
    @IBOutlet weak var statusR3C4: UILabel!
    
    @IBOutlet weak var statusR4C1: UILabel!
    @IBOutlet weak var statusR4C2: UILabel!
    @IBOutlet weak var statusR4C3: UILabel!
    @IBOutlet weak var statusR4C4: UILabel!
    
    var isScanning = false
    var statusLED2 = false
    var statusRow1 = false
    var statusRow2 = false
    var statusRow3 = false
    var statusRow4 = false
    var statusColumn1 = false
    var statusColumn2 = false
    var statusColumn3 = false
    var statusColumn4 = false
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var settingCharacteristic: CBCharacteristic!
    var outputCharacteristic: CBCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セントラルマネージャ初期化
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // =========================================================================
    // MARK: CBCentralManagerDelegate
    
    // セントラルマネージャの状態が変化すると呼ばれる
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        
        println("state: \(central.state)")
    }
    
    // ペリフェラルを発見すると呼ばれる
    func centralManager(central: CBCentralManager!,
        didDiscoverPeripheral peripheral: CBPeripheral!,
        advertisementData: [NSObject : AnyObject]!,
        RSSI: NSNumber!)
    {
        println("発見したBLEデバイス: \(peripheral)")
        
        if peripheral.name != nil { // nilを検出した場合は先に進まない
            
            if peripheral.name.hasPrefix("konashi") {
                
                self.peripheral = peripheral
            
                // 接続開始
                self.centralManager.connectPeripheral(self.peripheral, options: nil)
            }
        }
    }
    
    // ペリフェラルへの接続が成功すると呼ばれる
    func centralManager(central: CBCentralManager!,
        didConnectPeripheral peripheral: CBPeripheral!)
    {
        println("接続成功！")
        
        // サービス探索結果を受け取るためにデリゲートをセット
        peripheral.delegate = self
        
        // サービス探索開始
        peripheral.discoverServices(nil)
    }
    
    // ペリフェラルへの接続が失敗すると呼ばれる
    func centralManager(central: CBCentralManager!,
        didFailToConnectPeripheral peripheral: CBPeripheral!,
        error: NSError!)
    {
        println("接続失敗・・・")
    }
    
    
    // =========================================================================
    // MARK:CBPeripheralDelegate
    
    // サービス発見時に呼ばれる
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        
        if (error != nil) {
            println("エラー: \(error)")
            return
        }
        
        let services: NSArray = peripheral.services
        
        println("\(services.count) 個のサービスを発見！ \(services)")
        
        for obj in services {
            
            if let service = obj as? CBService {
                
                // キャラクタリスティック探索開始
                peripheral.discoverCharacteristics(nil, forService: service)
            }
        }
    }
    
    // キャラクタリスティック発見時に呼ばれる
    func peripheral(peripheral: CBPeripheral!,
        didDiscoverCharacteristicsForService service: CBService!,
        error: NSError!)
    {
        if (error != nil) {
            println("エラー: \(error)")
            return
        }
        
        let characteristics: NSArray = service.characteristics
        println("\(characteristics.count) 個のキャラクタリスティックを発見！ \(characteristics)")
        
        for obj in characteristics {
            
            if let characteristic = obj as? CBCharacteristic {
                
                if characteristic.UUID.isEqual(CBUUID(string: "3000")) {
                    
                    self.settingCharacteristic = characteristic
                    println("KONASHI_PIO_SETTING_UUID を発見！")
                }
                else if characteristic.UUID.isEqual(CBUUID(string: "3002")) {
                    
                    self.outputCharacteristic = characteristic
                    println("KONASHI_PIO_OUTPUT_UUID を発見！")
                }
                // konashi の PIO_INPUT_NOTIFICATION キャラクタリスティック
                // PIO0
                else if characteristic.UUID.isEqual(CBUUID(string: "3003")) {

                    // 更新通知受け取りを開始する
                    peripheral.setNotifyValue(
                        true,
                        forCharacteristic: characteristic)
                }
                
                
//                (2015.06.16 元プログラムを一旦コメント)
//                else if characteristic.UUID.isEqual(CBUUID(string: "3003")) {
//                    
//                    // 更新通知受け取りを開始する
//                    peripheral.setNotifyValue(
//                        true,
//                        forCharacteristic: characteristic)
//                }

//                // (2015.06.16 とりあえずReadは使わずNotifyを使うことにした。)
//                // Read専用のキャラクタリスティックに限定して読み出す場合
//                else if characteristic.properties == CBCharacteristicProperties.Read {
//                    
//                    peripheral.readValueForCharacteristic(characteristic)
//                }
                
            }
        }
    }
    
    // データ書き込みが完了すると呼ばれる
    func peripheral(peripheral: CBPeripheral!,
        didWriteValueForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        if (error != nil) {
            println("書き込み失敗...error: \(error), characteristic uuid: \(characteristic.UUID)")
            return
        }
        
        println("書き込み成功！service uuid: \(characteristic.service.UUID), characteristic uuid: \(characteristic.UUID), value: \(characteristic.value)")
    }
    
    // Notify開始／停止時に呼ばれる
    func peripheral(peripheral: CBPeripheral!,
        didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        if error != nil {
            
            println("Notify状態更新失敗...error: \(error)")
        }
        else {
            println("Notify状態更新成功！characteristic UUID:\(characteristic.UUID), isNotifying: \(characteristic.isNotifying)")
        }
    }
    
    // データ更新時に呼ばれる
    func peripheral(peripheral: CBPeripheral!,
        didUpdateValueForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        
//        var valueSW1: NSInteger = 0
        var valuePIO: NSInteger = 0
        
        if error != nil {
            println("データ更新通知エラー: \(error)")
            return
        }
        
        println("データ更新！ characteristic UUID: \(characteristic.UUID), value: \(characteristic.value)")
    
//        (2015.06.16 元プログラムを一旦コメント)
//        characteristic.value.getBytes(&valueSW1, length: sizeof(NSInteger)) // NSData -> NSIntegerに変換
//        if valueSW1 == 1 {
//            self.statusSW1.text = "SW1 : ON "
//        }
//        else if valueSW1 == 0 {
//            self.statusSW1.text = "SW1 : OFF"
//        }
//        // 2015.06.10 0/1ではなく2/3のときがある?

        
        // PIO毎にswitch文で分岐してフラグを立てる
        
        characteristic.value.getBytes(&valuePIO, length: sizeof(NSInteger)) // NSData -> NSIntegerに変換
        
        println("データ更新！ valueRow: \(valuePIO)")
        
        switch valuePIO {
        case 17 :
            self.statusR1C1.text = "x"
        case 18 :
            self.statusR2C1.text = "x"
        case 20 :
            self.statusR3C1.text = "x"
        case 24 :
            self.statusR4C1.text = "x"
        case 33 :
            self.statusR1C2.text = "x"
        case 34 :
            self.statusR2C2.text = "x"
        case 36 :
            self.statusR3C2.text = "x"
        case 40 :
            self.statusR4C2.text = "x"
        case 65 :
            self.statusR1C3.text = "x"
        case 66 :
            self.statusR2C3.text = "x"
        case 68 :
            self.statusR3C3.text = "x"
        case 72 :
            self.statusR4C3.text = "x"
        case 129 :
            self.statusR1C4.text = "x"
        case 130 :
            self.statusR2C4.text = "x"
        case 132 :
            self.statusR3C4.text = "x"
        case 136 :
            self.statusR4C4.text = "x"
        default:
            self.statusR1C1.text = "-"
            self.statusR1C2.text = "-"
            self.statusR1C3.text = "-"
            self.statusR1C4.text = "-"
            self.statusR2C1.text = "-"
            self.statusR2C2.text = "-"
            self.statusR2C3.text = "-"
            self.statusR2C4.text = "-"
            self.statusR3C1.text = "-"
            self.statusR3C2.text = "-"
            self.statusR3C3.text = "-"
            self.statusR3C4.text = "-"
            self.statusR4C1.text = "-"
            self.statusR4C2.text = "-"
            self.statusR4C3.text = "-"
            self.statusR4C4.text = "-"
        }

    }
    
    // =========================================================================
    // MARK: Actions
    
    @IBAction func scanBtnTapped(sender: UIButton) {
        
        if !isScanning {
            
            isScanning = true
            
            self.centralManager.scanForPeripheralsWithServices(nil, options: nil)
            
            sender.setTitle("STOP SCAN", forState: UIControlState.Normal)
        }
        else {
            
            self.centralManager.stopScan()
            
            sender.setTitle("START SCAN", forState: UIControlState.Normal)
            
            isScanning = false
        }
    }
    

    // (2015.06.16 サンプルプログラムコメントアウト)
    @IBAction func ledBtnTapped(sender: UIButton) {
        
        if self.settingCharacteristic == nil || self.outputCharacteristic == nil {
            
            println("Konashi is not ready!")
            return;
        }
        
        // LED2を光らせる
        
        // 書き込みデータ生成（LED2）
        var value: CUnsignedChar = 0x01 << 1    // 0000 0010
//        var value: CUnsignedChar = 0x1E   // 0001 1111
        let data: NSData = NSData(bytes: &value, length: 1)
        
        // konashi の pinMode:mode: で LED2 のモードを OUTPUT にすることに相当
        self.peripheral.writeValue(
            data,
            forCharacteristic: self.settingCharacteristic,
            type: CBCharacteristicWriteType.WithoutResponse)
        
        if !statusLED2{
            
            statusLED2 = true
            
            // 書き込みデータ生成（LED2）
            var value: CUnsignedChar = 0x01 << 1    // 0000 0010
//            var value: CUnsignedChar = 0x1E   // 0001 1111
            let data: NSData = NSData(bytes: &value, length: 1)
            
            // konashiの digitalWrite:value: で LED2 を HIGH にすることに相当
            self.peripheral.writeValue(
                data,
                forCharacteristic: self.outputCharacteristic,
                type: CBCharacteristicWriteType.WithoutResponse)
            
            sender.setTitle("LED2 OFF", forState: UIControlState.Normal)
        }
        else {

            statusLED2 = false
            
            // 書き込みデータ生成（LED2）
            var value: CUnsignedChar = 0x00 << 1
            let data: NSData = NSData(bytes: &value, length: 1)
            
            // konashiの digitalWrite:value: で LED2 を LOW にすることに相当
            self.peripheral.writeValue(
                data,
                forCharacteristic: self.outputCharacteristic,
                type: CBCharacteristicWriteType.WithoutResponse)
            
            sender.setTitle("LED2 ON", forState: UIControlState.Normal)
            
        }
        
    }
    
    @IBAction func col1BtnTapped(sender: AnyObject) {
    
        // Konashi接続確認
        if self.settingCharacteristic == nil || self.outputCharacteristic == nil {
            
            println("Konashi is not ready!")
            return;
        }
        
        // PIO設定
        
        // 書き込みデータ生成
        var value: CUnsignedChar = 0x10    // 0001 0000
//        var value: CUnsignedChar = 0xF0 << 1
        let data: NSData = NSData(bytes: &value, length: 1)
        
        // konashi の pinMode:mode: で LED2 のモードを OUTPUT にすることに相当
        self.peripheral.writeValue(
            data,
            forCharacteristic: self.settingCharacteristic,
            type: CBCharacteristicWriteType.WithoutResponse)
        
        // DO ON
        
        if !statusColumn1{
            
            statusColumn1 = true
            
            // 書き込みデータ生成（LED2）
            var value: CUnsignedChar = 0x10    // 0001 0000
//            var value: CUnsignedChar = 0x08    // 0000 1000
            let data: NSData = NSData(bytes: &value, length: 1)
            
            // konashiの digitalWrite:value: で LED2 を HIGH にすることに相当
            self.peripheral.writeValue(
                data,
                forCharacteristic: self.outputCharacteristic,
                type: CBCharacteristicWriteType.WithoutResponse)
            
            sender.setTitle("Col1+", forState: UIControlState.Normal)
        }
        else {
            
            statusColumn1 = false
            
            // 書き込みデータ生成（LED2）
            var value: CUnsignedChar = 0x00 << 1
            let data: NSData = NSData(bytes: &value, length: 1)
            
            // konashiの digitalWrite:value: で LED2 を LOW にすることに相当
            self.peripheral.writeValue(
                data,
                forCharacteristic: self.outputCharacteristic,
                type: CBCharacteristicWriteType.WithoutResponse)
            
            sender.setTitle("Col1", forState: UIControlState.Normal)
            
        }
        
    }
    
    @IBAction func col2BtnTapped(sender: AnyObject) {
        // Konashi接続確認
        if self.settingCharacteristic == nil || self.outputCharacteristic == nil {
            
            println("Konashi is not ready!")
            return;
        }
        
        // PIO設定
        
        // 書き込みデータ生成
        var value: CUnsignedChar = 0x20    // 0010 0000
//        var value: CUnsignedChar = 0xF0 << 1
        let data: NSData = NSData(bytes: &value, length: 1)
        
        // konashi の pinMode:mode: で LED2 のモードを OUTPUT にすることに相当
        self.peripheral.writeValue(
            data,
            forCharacteristic: self.settingCharacteristic,
            type: CBCharacteristicWriteType.WithoutResponse)
        
        // DO ON
        
        if !statusColumn1{
            
            statusColumn1 = true
            
            // 書き込みデータ生成（LED2）
            var value: CUnsignedChar = 0x20    // 0010 0000
//            var value: CUnsignedChar = 0x04    // 0000 0100
            let data: NSData = NSData(bytes: &value, length: 1)
            
            // konashiの digitalWrite:value: で LED2 を HIGH にすることに相当
            self.peripheral.writeValue(
                data,
                forCharacteristic: self.outputCharacteristic,
                type: CBCharacteristicWriteType.WithoutResponse)
            
            sender.setTitle("Col2+", forState: UIControlState.Normal)
        }
        else {
            
            statusColumn1 = false
            
            // 書き込みデータ生成（LED2）
            var value: CUnsignedChar = 0x00 << 1
            let data: NSData = NSData(bytes: &value, length: 1)
            
            // konashiの digitalWrite:value: で LED2 を LOW にすることに相当
            self.peripheral.writeValue(
                data,
                forCharacteristic: self.outputCharacteristic,
                type: CBCharacteristicWriteType.WithoutResponse)
            
            sender.setTitle("Col2", forState: UIControlState.Normal)
            
        }

        
    }
    
    @IBAction func col3BtnTapped(sender: AnyObject) {
    
        // Konashi接続確認
        if self.settingCharacteristic == nil || self.outputCharacteristic == nil {
            
            println("Konashi is not ready!")
            return;
        }
        
        // PIO設定
        
        // 書き込みデータ生成
        var value: CUnsignedChar = 0x40    // 0100 0000
//        var value: CUnsignedChar = 0xF0 << 1
        let data: NSData = NSData(bytes: &value, length: 1)
        
        // konashi の pinMode:mode: で LED2 のモードを OUTPUT にすることに相当
        self.peripheral.writeValue(
            data,
            forCharacteristic: self.settingCharacteristic,
            type: CBCharacteristicWriteType.WithoutResponse)
        
        // DO ON
        
        if !statusColumn1{
            
            statusColumn1 = true
            
            // 書き込みデータ生成（LED2）
            var value: CUnsignedChar = 0x40    // 0100 0000
//            var value: CUnsignedChar = 0x02    // 0000 0010
            let data: NSData = NSData(bytes: &value, length: 1)
            
            // konashiの digitalWrite:value: で LED2 を HIGH にすることに相当
            self.peripheral.writeValue(
                data,
                forCharacteristic: self.outputCharacteristic,
                type: CBCharacteristicWriteType.WithoutResponse)
            
            sender.setTitle("Col3+", forState: UIControlState.Normal)
        }
        else {
            
            statusColumn1 = false
            
            // 書き込みデータ生成（LED2）
            var value: CUnsignedChar = 0x00 << 1
            let data: NSData = NSData(bytes: &value, length: 1)
            
            // konashiの digitalWrite:value: で LED2 を LOW にすることに相当
            self.peripheral.writeValue(
                data,
                forCharacteristic: self.outputCharacteristic,
                type: CBCharacteristicWriteType.WithoutResponse)
            
            sender.setTitle("Col3", forState: UIControlState.Normal)
            
        }

        
    }
    
    @IBAction func col4BtnTapped(sender: AnyObject) {
    
        // Konashi接続確認
        if self.settingCharacteristic == nil || self.outputCharacteristic == nil {
            
            println("Konashi is not ready!")
            return;
        }
        
        // PIO設定
        
        // 書き込みデータ生成
        var value: CUnsignedChar = 0x80    // 1000 0000
//        var value: CUnsignedChar = 0xF0 << 1
        let data: NSData = NSData(bytes: &value, length: 1)
        
        // konashi の pinMode:mode: で LED2 のモードを OUTPUT にすることに相当
        self.peripheral.writeValue(
            data,
            forCharacteristic: self.settingCharacteristic,
            type: CBCharacteristicWriteType.WithoutResponse)
        
        // DO ON
        
        if !statusColumn1{
            
            statusColumn1 = true
            
            // 書き込みデータ生成（LED2）
            var value: CUnsignedChar = 0x80    // 1000 0000
//            var value: CUnsignedChar = 0x01    // 0000 0001
            let data: NSData = NSData(bytes: &value, length: 1)
            
            // konashiの digitalWrite:value: で LED2 を HIGH にすることに相当
            self.peripheral.writeValue(
                data,
                forCharacteristic: self.outputCharacteristic,
                type: CBCharacteristicWriteType.WithoutResponse)
            
            sender.setTitle("Col4+", forState: UIControlState.Normal)
        }
        else {
            
            statusColumn1 = false
            
            // 書き込みデータ生成（LED2）
            var value: CUnsignedChar = 0x00 << 1
            let data: NSData = NSData(bytes: &value, length: 1)
            
            // konashiの digitalWrite:value: で LED2 を LOW にすることに相当
            self.peripheral.writeValue(
                data,
                forCharacteristic: self.outputCharacteristic,
                type: CBCharacteristicWriteType.WithoutResponse)
            
            sender.setTitle("Col4", forState: UIControlState.Normal)
            
        }

        
    }
    
}

