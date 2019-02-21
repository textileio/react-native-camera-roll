
# @textile/react-native-camera-roll

A dead simple camera-roll polling endpoint.

1. Request a new check for photos since forever

```javascript
import CameraRoll from '@textile/react-native-camera-roll'

const minEpoch = 0
CameraRoll.requestLocalPhotos(minEpoch)
```

2. Listen for photos detected

```javascript
import { eventEmitter as Events, ILocalPhotoResult } from '@textile/react-native-camera-roll'

Events.addListener('@textile/newLocalPhoto', (localPhoto: ILocalPhotoResult) => {
	// Do something
})
```

## Getting started

`$ npm install @textile/react-native-camera-roll --save`

### Mostly automatic installation

`$ react-native link @textile/react-native-camera-roll`

### Manual installation

#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `@textile/react-native-camera-roll` and add `RNCameraRoll.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNCameraRoll.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import io.textile.cameraroll.RNCameraRollPackage;` to the imports at the top of the file
  - Add `new RNCameraRollPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-camera-roll'
  	project(':react-native-camera-roll').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-camera-roll/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-camera-roll')
  	```


## Usage
```javascript
import CameraRoll from '@textile/react-native-camera-roll';

// TODO: What to do with the module?
CameraRoll;
```
  
