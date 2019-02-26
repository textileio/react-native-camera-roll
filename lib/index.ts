import {
  DeviceEventEmitter,
  NativeEventEmitter,
  NativeModules,
  Platform
} from 'react-native'

const { CameraRollEvents } = NativeModules

export interface ILocalPhotoResult {
  assetId: string,
  creationDate: string,
  modificationDate: string,
  orientation: number,
  path: string,
  uri: string,
  canDelete: boolean
}

// TODO: change api function to return array of results
// export const eventEmitter = Platform.select({
//   android: DeviceEventEmitter,
//   ios: new NativeEventEmitter(CameraRollEvents)
// })

export * from './API'
