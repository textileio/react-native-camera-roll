import { NativeModules } from 'react-native'

const { RNCameraRoll } = NativeModules

export async function requestLocalPhotos(minEpoch: number): Promise<void> {
  return await RNCameraRoll.requestLocalPhotos(Math.round(minEpoch / 1000))
}
