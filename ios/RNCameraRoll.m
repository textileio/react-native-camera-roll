#import "RNCameraRoll.h"
#import "RNCameraRollEvents.h"
#import <Photos/Photos.h>

// import RCTBridge
#if __has_include(<React/RCTBridge.h>)
#import <React/RCTBridge.h>
#elif __has_include(“RCTBridge.h”)
#import “RCTBridge.h”
#else
#import “React/RCTBridge.h” // Required when used as a Pod in a Swift project
#endif

@interface AssetData : NSObject

@property PHAsset *asset;
@property NSString *path;
@property UIImageOrientation orientation;

- (NSComparisonResult)compare:(AssetData *)otherObject;

@end

@implementation AssetData

- (NSComparisonResult)compare:(AssetData *)otherObject {
  NSDate *selfDate = [self.asset valueForKey:@"modificationDate"];
  NSDate *otherDate = [otherObject.asset valueForKey:@"modificationDate"];
  return [selfDate compare:otherDate];
}
@end

@implementation RNCameraRoll

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue {
  return dispatch_queue_create("io.textile.CameraRollQueue", DISPATCH_QUEUE_SERIAL);
}

RCT_EXPORT_METHOD(requestLocalPhotos:(int)minEpoch resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSTimeInterval seconds = minEpoch;
  NSDate *epochNSDate = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
  PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
  if (status == PHAuthorizationStatusAuthorized)
  {
    //initialize empty local state
    @autoreleasepool
    {
      //fetch all the albums
      PHFetchOptions *onlyImagesOptions = [PHFetchOptions new];
      // Limit to only photo media types
      // NSPredicate *mediaPhotos = [NSPredicate predicateWithFormat:@"mediaType = %i", PHAssetMediaTypeImage];
      // Limit to only photos modified later than or equal to our specified date
      NSPredicate *minDate = [NSPredicate predicateWithFormat:@"modificationDate > %@", epochNSDate];
      // Limit to camera roll?
      // NSPredicate *cameraRoll = [NSPredicate predicateWithFormat:@"modificationDate > %@", epochNSDate];
      onlyImagesOptions.predicate = minDate;
      // Combine the multiple predicates (didn't seem to work combining them like this)
      // [NSCompoundPredicate orPredicateWithSubpredicates:@[mediaPhotos, minDate]];
      // Not sure we really need to do the sort... but here it is
      onlyImagesOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:YES]];

      PHFetchResult *allPhotosResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:onlyImagesOptions];

      NSMutableArray<AssetData*> *assetDatas = [[NSMutableArray alloc] init];

      dispatch_group_t assetDatasGroup = dispatch_group_create();

      [allPhotosResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {

        // Get the original filename to keep it straight on the system.
        // Alternatively could probably just use timestamp, but this doesn't seem to have any lag
        NSArray *resources = [PHAssetResource assetResourcesForAsset:asset];

        NSString *orgFilename = ((PHAssetResource*)resources[0]).originalFilename;

        // Check that this isn't a metadata edit only. adjustmentTimestamp should be pixel changes
        NSDate *adjDate = [asset valueForKey:@"adjustmentTimestamp"];
        // Grab the first creation date for the photo file
        NSDate *creDate = [asset valueForKey:@"creationDate"];
        if (adjDate != nil && [epochNSDate timeIntervalSinceDate:adjDate] > 0 ) {
          // if adjustmentTimestamp is less than our filter, we should return
          return;
        } else if (adjDate == nil && [epochNSDate timeIntervalSinceDate:creDate] > 0) {
          // if creation timestamp is less than our filter and the image has never been modified, return
          return;
        } else {
          dispatch_group_enter(assetDatasGroup);
          [self _writeToDisk:asset orgFilename:orgFilename onComplete:^(NSString *path, UIImageOrientation orientation) {
            if (path) {
              AssetData *data = [[AssetData alloc] init];
              data.asset = asset;
              data.path = path;
              data.orientation = orientation;
              [assetDatas addObject:data];
            }
            dispatch_group_leave(assetDatasGroup);
          }];
        }
      }];

      // assetDatas fully populated now
      [assetDatas sortUsingSelector:@selector(compare:)];

      NSMutableArray<NSDictionary*> *results = [[NSMutableArray alloc] initWithCapacity:assetDatas.count];

      [assetDatas enumerateObjectsUsingBlock:^(AssetData *assetData, NSUInteger idx, BOOL *stop) {
        [results addObject:[self _convertAssetData:assetData]];
      }];

      resolve(results);
    }
  } else {
    reject(@"1", @"no photos permission", [[NSError alloc] initWithDomain:@"io.textile" code:1 userInfo:nil]);
  }
}

- (void)_writeToDisk:(PHAsset *)asset orgFilename:(NSString *)orgFilename onComplete:(void (^_Nonnull)(NSString*, UIImageOrientation))onComplete  {
  // If the file isn't a HEIC, just write it to temp and move along.
  PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
//  requestOptions.synchronous = @TRUE;
  [[PHImageManager defaultManager] requestImageDataForAsset:asset options:requestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation imageOrientation, NSDictionary * _Nullable info) {
    // Got the image data for copying
    if (imageData) {
      UIImage *image = [UIImage imageWithData:imageData];
      NSData *jpegData = UIImageJPEGRepresentation(image, 1.0);
      NSString *jpgFilename = [NSString stringWithFormat:@"%@.%@", [orgFilename stringByDeletingPathExtension], @"jpg"];
      // Get our path in the tmp directory
      NSString *path = [[NSTemporaryDirectory() stringByStandardizingPath] stringByAppendingPathComponent:jpgFilename];

      // Write the data to the temp file
      BOOL success = [jpegData writeToFile:path atomically:YES];
      if (success) {
        onComplete(path, imageOrientation);
      } else {
        onComplete(nil, imageOrientation);
      }
    } else {
      onComplete(nil, imageOrientation);
    }
  }];
}

- (NSDictionary*)_convertAssetData:(AssetData *)assetData {
  // Setup date-string conversion
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  // Ensure date string is always in UTC
  [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
  [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];

  // creationDate is also available, but seems to be pure exif date
  NSDate *newDate = assetData.asset.modificationDate;
  NSDate *creationDate = assetData.asset.creationDate;
  // dataWithJSONObject cannot include NSDate
  NSString *dateString = [dateFormatter stringFromDate:newDate];
  NSString *creationDateString = [dateFormatter stringFromDate:creationDate];
  // get an int
  NSNumber *orientation = assetData.orientation ? [NSNumber numberWithInteger:assetData.orientation] : [NSNumber numberWithInt:1];

  NSDictionary *payload = @{
                            @"uri": assetData.path,
                            @"path": assetData.path,
                            @"modificationDate": dateString,
                            @"creationDate": creationDateString,
                            @"assetId": assetData.asset.localIdentifier,
                            @"orientation": orientation,
                            @"canDelete": @true
                            };
  return payload;
}

@end

@implementation RCTBridge (RNCameraRoll)

- (RNCameraRoll *)cameraRoll {
  return [self moduleForClass:[RNCameraRoll class]];
}

@end
