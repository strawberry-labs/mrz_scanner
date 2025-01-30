<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

Scan and parse MRZ (Machine Readable Zone) from identity documents (passport, id, visa) in iOS and Android. 

## Getting started

1. Install the package. 

```shell
flutter pub add mrz_scanner
```

OR

- Download the package from - (Insert link)
- place it in the root of your project
- add the following to your pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  mrz_scanner: #or Whatever is the folder's name
    path: './mrz_flutter_package'  #or Whatever is the folder's name
```

2. Add the following permissions to the ```AndroidManifest.xml``` file

```XML
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.VIBRATE"/>
    .
    .
    .
</manifest>
```

3. To trigger the MRZScanner, add the following code wherever you need: 

```dart
import 'package:mrz_scanner/mrz_scanner.dart';

final result = await NavigationHelper.navigateToMRZScanner(context);
```

This will navigate to the mrz scanner screen. Once a document is scanned, it will return the data and store it in result. 

The data returned will be a ```String```. 

Look at the example for more clarity. 

<!-- ## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
``` -->

<!-- ## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more. -->
