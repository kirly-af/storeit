package com.storeit.storeit.ipfs;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.support.v7.app.NotificationCompat;
import android.util.Log;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.storeit.storeit.R;
import org.apache.commons.io.IOUtils;
import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class DownloadAsync extends AsyncTask<String, Integer, Boolean> {
    private NotificationManager mNotifyManager;
    private android.support.v4.app.NotificationCompat.Builder mBuilder;
    private int id = 1;
    private Context mContext;

    public DownloadAsync(Context context) {
        mContext = context;
    }

    protected void onPreExecute() {
        super.onPreExecute();

        Intent intent = new Intent("ipfsManip");
        intent.putExtra("result", "cancel");
        intent.putExtra("type", "download");
        PendingIntent pendingIntent = PendingIntent.getBroadcast(mContext, 0, intent, 0);

        mNotifyManager = (NotificationManager) mContext.getSystemService(Context.NOTIFICATION_SERVICE);
        mBuilder = new NotificationCompat.Builder(mContext)
                .setContentTitle("StoreIt")
                .setContentText("Download in progress")
                .setSmallIcon(R.drawable.ic_insert_drive_file_black_24dp)
                .addAction(R.drawable.ic_insert_drive_file_black_24dp, "Cancel", pendingIntent)
                .setDeleteIntent(pendingIntent);
        mBuilder.setProgress(100, 0, false);

        Notification n = mBuilder.build();
        n.flags = Notification.FLAG_ONGOING_EVENT | Notification.FLAG_NO_CLEAR;
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        mNotifyManager.notify(id, n);
    }

    @Override
    protected void onPostExecute(Boolean response) {
        Intent intent = new Intent("ipfsManip");

        if (!response) {
            intent.putExtra("result", "error");
            intent.putExtra("type", "download");
            PendingIntent pendingIntent = PendingIntent.getBroadcast(mContext, 0, intent, 0);

            mBuilder.setContentText("Error while downloading...")
                    .setProgress(0, 0, false)
                    .setContentIntent(pendingIntent);


        } else {
            intent.putExtra("result", "success");
            intent.putExtra("type", "download");
            PendingIntent pendingIntent = PendingIntent.getBroadcast(mContext, 0, intent, 0);

            mBuilder.setContentText("Download finished")
                    .setProgress(0, 0, false)
                    .setContentIntent(pendingIntent);
        }

        Notification n = mBuilder.build();
        n.flags = Notification.FLAG_ONGOING_EVENT | Notification.FLAG_NO_CLEAR;
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        mNotifyManager.notify(id, n);
    }

    @Override
    protected void onProgressUpdate(Integer... progress) {
        Intent intent = new Intent("ipfsManip");
        intent.putExtra("result", "cancel");
        intent.putExtra("type", "download");
        PendingIntent pendingIntent = PendingIntent.getBroadcast(mContext, 0, intent, 0);

        mBuilder.setProgress(100, progress[0], false).setContentIntent(pendingIntent);


        Notification n = mBuilder.build();
        n.flags = Notification.FLAG_ONGOING_EVENT | Notification.FLAG_NO_CLEAR;
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        mNotifyManager.notify(id, n);
    }

    private long getFileSize(String hash) {

        String nodeUrl = "http://127.0.0.1";

        URL url = null;
        HttpURLConnection urlConnection = null;
        long size = -1;

        try {
            url = new URL(nodeUrl + ":5001/api/v0/object/stat?arg=" + hash);
            urlConnection = (HttpURLConnection) url.openConnection();
            urlConnection.setConnectTimeout(20000);
            InputStream in = new BufferedInputStream(urlConnection.getInputStream());

            String result = IOUtils.toString(in);

            JsonParser parser = new JsonParser();
            JsonObject obj = parser.parse(result).getAsJsonObject();
            size = obj.get("CumulativeSize").getAsLong();
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (urlConnection != null) {
                urlConnection.disconnect();
            }
        }
        Log.v("DownloadAsync", "File size : " + size);
        return size;
    }

    @Override
    protected Boolean doInBackground(String... params) {

        String path = params[0];
        String hash = params[1];

        File filePath = new File(path);
        File file = new File(filePath, hash);

        long fileSize = getFileSize(hash);
        if (fileSize == -1)
            return false;

        FileOutputStream outputStream = null;

        try {
            if (!file.exists()) {
                if (!file.createNewFile()) {
                    Log.e("DownloadAsync", "Error while creating " + file);
                }
            }

            outputStream = new FileOutputStream(file);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            if (!file.delete()) {
                Log.v("DownloadAsync", "Error while deleting file");
            }
            return false;
        } catch (IOException e) {
            e.printStackTrace();
            if (!file.delete()) {
                Log.v("DownloadAsync", "Error while deleting file");
            }
        }
        if (outputStream == null) {
            if (!file.delete()) {
                Log.v("DownloadAsync", "Error while deleting file");
            }
            return false;
        }

        HttpURLConnection connection;
        URL url;



        String m_nodeUrl = "http://127.0.0.1:8080/ipfs/";
        try {
            url = new URL(m_nodeUrl + hash);
            connection = (HttpURLConnection) url.openConnection();

            connection.setRequestMethod("GET"); // Create the get request
            connection.setReadTimeout(50000);
            int responseCode = connection.getResponseCode();
            if (responseCode != HttpURLConnection.HTTP_OK)
                return false;

            // Get connection stream
            InputStream is = connection.getInputStream();
            // Byte wich will contain the response byte
            byte[] buffer = new byte[4096];

            int bytesRead;
            long total = 0;
            Integer count;
            long startTime = System.currentTimeMillis();
            long elapsedTime = 0L;

            while ((bytesRead = is.read(buffer)) != -1) {
                outputStream.write(buffer, 0, bytesRead);

                total += bytesRead;
                count = (int) (total * 100 / fileSize);

                elapsedTime = System.currentTimeMillis() - startTime;

                if (elapsedTime > 500) {
                    publishProgress(count);
                    startTime = System.currentTimeMillis();
                }
            }
            outputStream.close();

        } catch (IOException e) {
            try {
                e.printStackTrace();
                outputStream.close();
            } catch (IOException e1) {
                e1.printStackTrace();
            } finally {
                if (!file.delete()) {
                    Log.v("DownloadAsync", "Error while deleting file");
                }
            }
            return false;
        }
        return true;
    }
}
