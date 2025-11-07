package org.haxe.lime;

import android.content.Context;
import android.content.Intent;
import android.content.ClipData;
import android.app.Activity;
import android.content.ContentResolver;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.ParcelFileDescriptor;
import android.net.Uri;
import android.util.Log;
import android.widget.Toast;
import android.provider.DocumentsContract;
import android.webkit.MimeTypeMap;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.haxe.extension.Extension;
import org.haxe.lime.HaxeObject;

import org.haxe.lime.GameActivity;

/*
	You can use the Android Extension class in order to hook
	into the Android activity lifecycle. This is not required
	for standard Java code, this is designed for when you need
	deeper integration.

	You can access additional references from the Extension class,
	depending on your needs:

	- Extension.assetManager (android.content.res.AssetManager)
	- Extension.callbackHandler (android.os.Handler)
	- Extension.mainActivity (android.app.Activity)
	- Extension.mainContext (android.content.Context)
	- Extension.mainView (android.view.View)

	You can also make references to static or instance methods
	and properties on Java classes. These classes can be included
	as single files using <java path="to/File.java" /> within your
	project, or use the full Android Library Project format (such
	as this example) in order to include your own AndroidManifest
	data, additional dependencies, etc.

	These are also optional, though this example shows a static
	function for performing a single task, like returning a value
	back to Haxe from Java.
*/
public class FileDialog extends Extension
{
	public static final String LOG_TAG = "FileDialog";
	private static final int OPEN_REQUEST_CODE = 990;
	private static final int OPEN_MULTIPLE_REQUEST_CODE = 995;
	private static final int SAVE_REQUEST_CODE = 999;
	private static final int DOCUMENT_TREE_REQUEST_CODE = 1000;

	public HaxeObject haxeObject;
	public FileSaveCallback onFileSave = null;
	// that's to prevent multiple FileDialogs from dispatching each others
	// kind it's kinda a shitty to handle it but idk anything better rn
	public boolean awaitingResults = false;

	public FileDialog(final HaxeObject haxeObject)
	{
		this.haxeObject = haxeObject;
	}

	public static FileDialog createInstance(final HaxeObject haxeObject)
	{
		return GameActivity.creatFileDialog(haxeObject);
	}

	public void open(String filter, String defaultPath, String title)
	{
		Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
		intent.addCategory(Intent.CATEGORY_OPENABLE);

		if (defaultPath != null)
		{
			//Log.d(LOG_TAG, "setting open dialog inital path...");
			File file = new File(defaultPath);
			if (file.exists())
			{
				Uri uri = Uri.fromFile(file);
				intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, uri);
				//Log.d(LOG_TAG, "Set to " + uri.getPath() + "!");
			}
			else
			{
				//Log.d(LOG_TAG, "Uh Oh the path doesn't exist :(");
			}
		}

		if (filter != null)
		{
			if (filter.contains(","))
			{
				String[] filters = filter.split(",");

				for (int i = 0; i < filters.length; i++)
				{
					filters[i] = getMimeFromExtension(filters[i]);
				}

				intent.setType(filters[0]);
				intent.putExtra(Intent.EXTRA_MIME_TYPES, filters);
			}
			else
			{
				String mime = getMimeFromExtension(filter);
				intent.setType(getMimeFromExtension(filter));
			}
		}
		else
		{
			intent.setType("*/*");
		}

		if (title != null)
		{
			//Log.d(LOG_TAG, "Setting title to " + title);
			intent.putExtra(Intent.EXTRA_TITLE, title);
		}
		
		//Log.d(LOG_TAG, "launching file picker (ACTION_OPEN_DOCUMENT) intent!");
		awaitingResults = true;
		mainActivity.startActivityForResult(intent, OPEN_REQUEST_CODE);
	}

	public void openMultiple(String filter, String defaultPath, String title)
	{
		Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
		intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
		intent.addCategory(Intent.CATEGORY_OPENABLE);

		if (defaultPath != null)
		{
			//Log.d(LOG_TAG, "setting open dialog inital path...");
			File file = new File(defaultPath);
			if (file.exists())
			{
				Uri uri = Uri.fromFile(file);
				intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, uri);
				//Log.d(LOG_TAG, "Set to " + uri.getPath() + "!");
			}
			else
			{
				//Log.d(LOG_TAG, "Uh Oh the path doesn't exist :(");
			}
		}

		if (filter != null)
		{
			if (filter.contains(","))
			{
				String[] filters = filter.split(",");

				for (int i = 0; i < filters.length; i++)
				{
					filters[i] = getMimeFromExtension(filters[i]);
				}

				intent.setType(filters[0]);
				intent.putExtra(Intent.EXTRA_MIME_TYPES, filters);
			}
			else
			{
				String mime = getMimeFromExtension(filter);
				intent.setType(getMimeFromExtension(filter));
			}
		}
		else
		{
			intent.setType("*/*");
		}

		if (title != null)
		{
			//Log.d(LOG_TAG, "Setting title to " + title);
			intent.putExtra(Intent.EXTRA_TITLE, title);
		}
		
		//Log.d(LOG_TAG, "launching file picker (ACTION_OPEN_DOCUMENT) intent!");
		awaitingResults = true;
		mainActivity.startActivityForResult(intent, OPEN_MULTIPLE_REQUEST_CODE);
	}

	public void save(byte[] data, String mime, String defaultPath, String title)
	{
		Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
		intent.addCategory(Intent.CATEGORY_OPENABLE);

		if (defaultPath != null)
		{
			//Log.d(LOG_TAG, "setting save dialog inital path...");
			File file = new File(defaultPath);
			if (file.exists())
			{
				Uri uri = Uri.fromFile(file);
				intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, uri);
				//Log.d(LOG_TAG, "Set to " + uri.getPath() + "!");
			}
			else
			{
				//Log.d(LOG_TAG, "Uh Oh the path doesn't exist :(");
			}
		}

		if (title != null)
		{
			//Log.d(LOG_TAG, "Setting title to " + title);
			intent.putExtra(Intent.EXTRA_TITLE, title);
		}

		if  (data != null)
		{
			onFileSave = new FileSaveCallback()
			{
        		@Override
        		public void execute(Uri uri)
				{
					//Log.d(LOG_TAG, "Saving File to " + uri.toString());
					writeBytesToFile(uri, data);
        	    }
        	};
		}
		else
		{
			Log.w(LOG_TAG, "No bytes data were passed to `save`, no bytes will be written to it.");
		}
		
		//Log.d(LOG_TAG, "launching file saver (ACTION_CREATE_DOCUMENT) intent!");
		awaitingResults = true;
		
		if (mime == "application/octet-stream")
			mime = "*/*";
		intent.setType(mime);
		mainActivity.startActivityForResult(intent, SAVE_REQUEST_CODE);
	}

	public void openDocumentTree(String defaultPath)
    {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        intent.addCategory(Intent.CATEGORY_DEFAULT);
	
		if (defaultPath != null)
		{
			//Log.d(LOG_TAG, "setting document tree dialog inital path...");
			File file = new File(defaultPath);
			if (file.exists())
			{
				Uri uri = Uri.fromFile(file);
				intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, uri);
				//Log.d(LOG_TAG, "Set to " + uri.getPath() + "!");
			}
			else
			{
				//Log.d(LOG_TAG, "Uh Oh the path doesn't exist :(");
			}
		}

		//Log.d(LOG_TAG, "launching directory picker (ACTION_OPEN_DOCUMENT_TREE) intent!");
		awaitingResults = true;
        mainActivity.startActivityForResult(intent, DOCUMENT_TREE_REQUEST_CODE);
    }

	public static void getPersistableURIAccess(String uriStr)
	{
		mainContext.getContentResolver().takePersistableUriPermission(Uri.parse(uriStr), Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
	}

	@Override
	public boolean onActivityResult(int requestCode, int resultCode, Intent data)
	{
		String uri = null;
		String path = null;
		// byte[] bytesData = null;

		if (haxeObject != null && awaitingResults)
		{
			if (resultCode == Activity.RESULT_OK && data != null)
			{
				switch (requestCode)
				{
					case OPEN_REQUEST_CODE:
						try
						{
							// Log.d(LOG_TAG, "Grabbing URI bytes: " + uri);
							// bytesData = getFileBytes(data.getData());
							path = copyURIToCache(data.getData());
						}
						catch (IOException e)
						{
							Log.e(LOG_TAG, "Failed to copy file to cache:" + e.getMessage());
						}
						break;
					case OPEN_MULTIPLE_REQUEST_CODE:
						try
						{
							if (data.getClipData() != null)
							{
                				ClipData clipData = data.getClipData();
								List<String> pathsList = new ArrayList<>();
                				for (int i = 0; i < clipData.getItemCount(); i++) {
                    				Uri fileUri = clipData.getItemAt(i).getUri();
									pathsList.add(copyURIToCache(fileUri));
	                			}
								path = String.join(",", pathsList);
							}
							else if (data.getData() != null)
							{
								path = copyURIToCache(data.getData());
							}
						}
						catch (IOException e)
						{
							Log.e(LOG_TAG, "Failed to copy file to cache:" + e.getMessage());
						}
						break;
					case SAVE_REQUEST_CODE:
						if (onFileSave != null && data.getData() != null)
						{
							onFileSave.execute(data.getData());
							onFileSave = null;
						}
						break;
					case DOCUMENT_TREE_REQUEST_CODE:
						//Log.d(LOG_TAG, "Got directory tree uri:" + uri.toString());
						break;
					default:
						break;
				}
			}
			else
			{
				Log.e(LOG_TAG, "Activity results for request code " + requestCode + " failed with result code " + resultCode + " and data " + data);
			}
		}

		Object[] args = new Object[4];
		args[0] = requestCode;
		args[1] = resultCode;
		if (data.getData() == null)
			args[2] = null;
		else
			args[2] = data.getData().toString();
		if (path != null) {
        	args[3] = path;
    	} else if (data != null && data.getData() != null) {
        	args[3] = data.getData().getPath();
    	} else {
      	  args[3] = null;
    	}
		//Log.d(LOG_TAG, "Dispatching activity results: " + uri);
		haxeObject.call("onJNIActivityResult", args); 

		awaitingResults = false;
		return true;
	}

	public static String formatExtension(String extension)
	{
		if (extension.startsWith("*") || extension.startsWith(".")) {
			extension = extension.substring(1);
		}

		return extension;
	}

	private static byte[] getFileBytes(Uri fileUri) throws IOException
	{
		ContentResolver contentResolver = mainContext.getContentResolver();
    	ParcelFileDescriptor parcelFileDescriptor = null;
    	FileInputStream fileInputStream = null;

    	try 
		{
    	    parcelFileDescriptor = contentResolver.openFileDescriptor(fileUri, "r");
    	    fileInputStream = new FileInputStream(parcelFileDescriptor.getFileDescriptor());

    	    byte[] fileBytes = new byte[(int) parcelFileDescriptor.getStatSize()];
    	    fileInputStream.read(fileBytes);

    	    return fileBytes;

    	}
		catch (IOException e)
		{
			Log.e(LOG_TAG, "Failed to get file bytes\n" + e.getMessage());
		}
		finally
		{
    	    // Close resources
    	    if (fileInputStream != null)
			{
    	        fileInputStream.close();
    	    }

    	    if (parcelFileDescriptor != null)
			{
    	        parcelFileDescriptor.close();
    	    }
    	}

		return new byte[0];
	}

	private static void writeBytesToFile(Uri uri, byte[] data)
	{
    	try
		{
        	// Open an OutputStream to the URI to write data to the file
        	OutputStream outputStream = mainContext.getContentResolver().openOutputStream(uri);

	        if (outputStream != null)
			{
        	    // Write the byte array to the file
            	outputStream.write(data);
				outputStream.close();  // Don't forget to close the stream
        	    Log.d(LOG_TAG, "File saved successfully.");
       		}
    	}
		catch (IOException e)
		{
        	Log.e(LOG_TAG, "Failed to save file: " + e.getMessage());
    	}
	}

	public static String copyURIToCache(Uri uri) throws IOException
	{
		if (uri != null) {
			String fileName = new File(uri.getPath()).getName();
			if (fileName.contains(":"))
				fileName = fileName.split(":")[1];
        	File output = new File(mainContext.getCacheDir(), fileName);
			Log.d(LOG_TAG, "Copying URI from '" + uri + "' to cache dir: " + output.getAbsolutePath());

			if (output.exists())
			{
				output.delete();
				Log.d(LOG_TAG, "deleting existing copy of: " + output.getAbsolutePath());
			}

    		ParcelFileDescriptor parcelFileDescriptor = null;
			FileInputStream fileInputStream = null;
			OutputStream out = null;

        	try {
	    	    parcelFileDescriptor = mainContext.getContentResolver().openFileDescriptor(uri, "r");
				fileInputStream = new FileInputStream(parcelFileDescriptor.getFileDescriptor());

				byte[] fileBytes = new byte[(int) parcelFileDescriptor.getStatSize()];
	    	    fileInputStream.read(fileBytes);
				
				out = new FileOutputStream(output);
				out.write(fileBytes);
        	}
        	catch (IOException e) {
            	Log.e(LOG_TAG, e.getMessage());
        	}
			finally
			{
	    	    if (fileInputStream != null)
				{
    		        fileInputStream.close();
    	    	}

    	    	if (parcelFileDescriptor != null)
				{
    	        	parcelFileDescriptor.close();
    	    	}

				if (out != null)
				{
					out.close();
				}
    		}

    		return output.getAbsolutePath();
		}

		return null;
	}

	public static String getMimeFromExtension(String extension)
	{
		MimeTypeMap mimeType = MimeTypeMap.getSingleton();
		extension = formatExtension(extension);
		String mime = mimeType.getMimeTypeFromExtension(extension);
		return mime != null ? mime : "*/*";
	}
}

@FunctionalInterface
interface FileSaveCallback
{
    void execute(Uri uri);
}
