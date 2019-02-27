import { NativeModules } from 'react-native'

const { RNCameraRoll } = NativeModules

export interface LocalPhotoResult {
  assetId: string,
  creationDate: string,
  modificationDate: string,
  orientation: number,
  path: string,
  uri: string,
  canDelete: boolean
}

export async function requestLocalPhotos(minEpoch: number): Promise<LocalPhotoResult[]> {
  return await RNCameraRoll.requestLocalPhotos(Math.round(minEpoch / 1000))
}
