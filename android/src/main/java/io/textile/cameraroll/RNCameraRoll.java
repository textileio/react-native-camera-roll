
package io.textile.cameraroll;

import android.database.Cursor;
import android.os.Environment;
import android.provider.MediaStore;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

public class RNCameraRoll extends ReactContextBaseJavaModule {

    public static final String REACT_CLASS = "RNCameraRoll";
    private static ReactApplicationContext reactContext = null;

    private Executor executor = Executors.newSingleThreadExecutor();

    public RNCameraRoll(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @ReactMethod
    public void requestLocalPhotos (final int minEpoch, final Promise promise) {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                // Get our camera bucket
                final String CAMERA_IMAGE_BUCKET_NAME = Environment.getExternalStorageDirectory().toString()
                        + "/DCIM/Camera";
                // Get our bucket ID
                final String CAMERA_IMAGE_BUCKET_ID = String.valueOf(CAMERA_IMAGE_BUCKET_NAME.toLowerCase().hashCode());
                // Get the fields we want
                final String[] projection = {
                        MediaStore.Images.Media.DATA,
                        MediaStore.Images.Media.DATE_MODIFIED,
                        MediaStore.Images.Media.DATE_ADDED,
                        MediaStore.Images.Media.ORIENTATION
                };
                // Setup the query. In our Bucket and with min date
                final String selection = MediaStore.Images.Media.BUCKET_ID
                        + " = ? AND "
                        + MediaStore.Images.Media.DATE_MODIFIED
                        + " > ?";

                final String[] selectionArgs = {CAMERA_IMAGE_BUCKET_ID, Integer.toString(minEpoch)};

                // Query
                final Cursor cursor = reactContext.getContentResolver().query(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        projection,
                        selection,
                        selectionArgs,
                        null);

                if (cursor.moveToFirst()) {
                    final int pathColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
                    final int modifiedColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_MODIFIED);
                    final int createdColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED);
                    final int orientationColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.ORIENTATION);

                    WritableArray results = Arguments.createArray();
                    do {
                        // Send a new event, newLocalPhoto
                        try {
                            // Grab the values out of the result row
                            final String path = cursor.getString(pathColumn);
                            final String modified = cursor.getString(modifiedColumn);
                            final String created = cursor.getString(createdColumn);
                            final String orientation = cursor.getString(orientationColumn);

                            WritableMap payload = Arguments.createMap();
                            payload.putString("assetId", path);
                            payload.putString("path", path);
                            payload.putString("creationDate", created);
                            payload.putString( "modificationDate", modified);
                            payload.putInt("orientation", Integer.parseInt(orientation));
                            payload.putBoolean("canDelete", false);

                            results.pushMap(payload);
                        } catch (Exception e) {
                            promise.reject("0", e.getMessage());
                        }
                    } while (cursor.moveToNext());
                    promise.resolve(results);
                } else {
                    promise.resolve(Arguments.createArray());
                }
                cursor.close();
            }
        });
    }
}
