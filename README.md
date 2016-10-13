A BarcodeScanner framework for iOS apps.

I'm using this wrapper framework so I could use the built-in scanning capabilities of iOS
within my [NativeScript BarcodeScanner plugin](https://www.npmjs.com/package/nativescript-barcodescanner).

### Note to self: building the framework
- Run the target for simulator and device (disconnect the device to be sure), make sure to not only build for the active architecture
- Right-click the file in the Products folder and open in Finder
- In a Terminal `cd` to that folder, move up to the `Products` folder
- Run `lipo -create -output "BarcodeScannerFramework" "Debug-iphonesimulator/BarcodeScannerFramework.framework/BarcodeScannerFramework" "Debug-iphoneos/BarcodeScannerFramework.framework/BarcodeScannerFramework"`
- Use the resulting `BarcodeScannerFramework` file instead of the one generated inside any of the target