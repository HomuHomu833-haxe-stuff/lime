package lime.ui;

import haxe.io.Bytes;
import haxe.io.Path;
import haxe.ds.Map;
import lime._internal.backend.native.NativeCFFI;
import lime.app.Event;
import lime.graphics.Image;
import lime.system.BackgroundWorker;
import lime.utils.ArrayBuffer;
import lime.utils.Resource;
import lime.system.JNI;
#if hl
import hl.Bytes as HLBytes;
import hl.NativeArray;
#end
#if sys
import sys.io.File;
#end
#if (js && html5)
import js.html.Blob;
#end

/**
	Simple file dialog used for asking user where to save a file, or select files to open.

	Example usage:
	```haxe
	var fileDialog = new FileDialog();

	fileDialog.onCancel.add( () -> trace("Canceled.") );

	fileDialog.onSave.add( path -> trace("File saved in " + path) );

	fileDialog.onOpen.add( res -> trace("Size of the file = " + (res:haxe.io.Bytes).length) );

	if ( fileDialog.open("jpg", null, "Load file") )
		trace("File dialog opened, waiting for selection...");
	else
		trace("This dialog is unsupported.");
	```

	Availability note: most file dialog operations are only available on desktop targets, though
	`save()` is also available in HTML5.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.graphics.Image)
class FileDialog #if android implements JNISafety #end
{
	/**
		Triggers when the user clicks "Cancel" during any operation, or when a function is unsupported
		(such as `open()` on HTML5).
	**/
	public var onCancel = new Event<Void->Void>();

	/**
		Triggers when `open()` is successful. The `lime.utils.Resource` contains the file's data, and can
		be implicitly cast to `haxe.io.Bytes`.
	**/
	public var onOpen = new Event<Resource->Void>();

	/**
		Triggers when `save()` is successful. The `String` is the path to the saved file.
	**/
	public var onSave = new Event<String->Void>();

	/**
		Triggers when `browse()` is successful and `type` is anything other than
		`FileDialogType.OPEN_MULTIPLE`. The `String` is the path to the selected file.
	**/
	public var onSelect = new Event<String->Void>();

	/**
		Triggers when `browse()` is successful and `type` is `FileDialogType.OPEN_MULTIPLE`. The
		`Array<String>` contains all selected file paths.
	**/
	public var onSelectMultiple = new Event<Array<String>->Void>();

	#if android
	private static final OPEN_REQUEST_CODE:Int = JNI.createStaticField('org/haxe/lime/FileDialog', 'OPEN_REQUEST_CODE', 'I').get();
	private static final OPEN_MULTIPLE_REQUEST_CODE:Int = JNI.createStaticField('org/haxe/lime/FileDialog', 'OPEN_MULTIPLE_REQUEST_CODE', 'I').get();
	private static final SAVE_REQUEST_CODE:Int = JNI.createStaticField('org/haxe/lime/FileDialog', 'SAVE_REQUEST_CODE', 'I').get();
	private static final DOCUMENT_TREE_REQUEST_CODE:Int = JNI.createStaticField('org/haxe/lime/FileDialog', 'DOCUMENT_TREE_REQUEST_CODE', 'I').get();
	private static final RESULT_OK:Int = -1;
	private var JNI_FILE_DIALOG:Dynamic = null;
	private var IS_SELECT:Bool = false;
	#elseif ios
	private static var registeredEvents:Bool = false;
	private static var eventHandler:FileDialogEventHanlder;
	private static var fileDialogInstances:Map<Int, FileDialog> = new Map<Int, FileDialog>();
	private var native_id:Int = -1;
	#end

	public function new()
	{
		#if android
		JNI_FILE_DIALOG = JNI.createStaticMethod('org/haxe/lime/FileDialog', 'createInstance', '(Lorg/haxe/lime/HaxeObject;)Lorg/haxe/lime/FileDialog;')(this);
		#elseif ios
		eventHandler = new FileDialogEventHanlder();
		native_id = NativeCFFI.lime_file_dialog_create_ios();
		fileDialogInstances.set(native_id, this);
		#end
	}

	/**
		Opens a file selection dialog. If successful, either `onSelect` or `onSelectMultiple` will trigger
		with the result(s).

		This function only works on desktop targets, and will return `false` otherwise.
		@param type 		Type of the file dialog: `OPEN`, `SAVE`, `OPEN_DIRECTORY` or `OPEN_MULTIPLE`.
		@param filter 		A filter to use when browsing. Asterisks are treated as wildcards. For example,
		`"*.jpg"` will match any file ending in `.jpg`.
		@param defaultPath 	The directory in which to start browsing and/or the default filename to
		suggest. Defaults to `Sys.getCwd()`, with no default filename.
		@param title 		The title to give the dialog window.
		@return Whether `browse()` is supported on this target.
	**/
	public function browse(type:FileDialogType = null, filter:String = null, defaultPath:String = null, title:String = null):Bool
	{
		if (type == null) type = FileDialogType.OPEN;

		#if desktop
		var worker = new BackgroundWorker();

		worker.doWork.add(function(_)
		{
			switch (type)
			{
				case OPEN:
					#if linux
					if (title == null) title = "Open File";
					#end

					var path = null;
					#if (!macro && lime_cffi)
					#if hl
					var bytes = NativeCFFI.lime_file_dialog_open_file(title, filter, defaultPath);
					if (bytes != null)
					{
						path = @:privateAccess String.fromUTF8(cast bytes);
					}
					#else
					path = NativeCFFI.lime_file_dialog_open_file(title, filter, defaultPath);
					#end
					#end

					worker.sendComplete(path);

				case OPEN_MULTIPLE:
					#if linux
					if (title == null) title = "Open Files";
					#end

					var paths = null;
					#if (!macro && lime_cffi)
					#if hl
					var bytes:NativeArray<HLBytes> = cast NativeCFFI.lime_file_dialog_open_files(title, filter, defaultPath);
					if (bytes != null)
					{
						paths = [];
						for (i in 0...bytes.length)
						{
							paths[i] = @:privateAccess String.fromUTF8(bytes[i]);
						}
					}
					#else
					paths = NativeCFFI.lime_file_dialog_open_files(title, filter, defaultPath);
					#end
					#end

					worker.sendComplete(paths);

				case OPEN_DIRECTORY:
					#if linux
					if (title == null) title = "Open Directory";
					#end

					var path = null;
					#if (!macro && lime_cffi)
					#if hl
					var bytes = NativeCFFI.lime_file_dialog_open_directory(title, filter, defaultPath);
					if (bytes != null)
					{
						path = @:privateAccess String.fromUTF8(cast bytes);
					}
					#else
					path = NativeCFFI.lime_file_dialog_open_directory(title, filter, defaultPath);
					#end
					#end

					worker.sendComplete(path);

				case SAVE:
					#if linux
					if (title == null) title = "Save File";
					#end

					var path = null;
					#if (!macro && lime_cffi)
					#if hl
					var bytes = NativeCFFI.lime_file_dialog_save_file(title, filter, defaultPath);
					if (bytes != null)
					{
						path = @:privateAccess String.fromUTF8(cast bytes);
					}
					#else
					path = NativeCFFI.lime_file_dialog_save_file(title, filter, defaultPath);
					#end
					#end

					worker.sendComplete(path);
			}
		});

		worker.onComplete.add(function(result)
		{
			switch (type)
			{
				case OPEN, OPEN_DIRECTORY, SAVE:
					var path:String = cast result;

					if (path != null)
					{
						// Makes sure the filename ends with extension
						if (type == SAVE && filter != null && path.indexOf(".") == -1)
						{
							path += "." + filter;
						}

						onSelect.dispatch(path);
					}
					else
					{
						onCancel.dispatch();
					}

				case OPEN_MULTIPLE:
					var paths:Array<String> = cast result;

					if (paths != null && paths.length > 0)
					{
						onSelectMultiple.dispatch(paths);
					}
					else
					{
						onCancel.dispatch();
					}
			}
		});

		worker.run();

		return true;
		#elseif android
		IS_SELECT = true;
		switch (type)
		{
			case OPEN:
				filter = StringTools.replace(filter, " ", "");
				JNI.callMember(JNI.createMemberMethod('org/haxe/lime/FileDialog', 'open', '(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V'), JNI_FILE_DIALOG, [filter, defaultPath, title]);
				return true;

			case OPEN_MULTIPLE:
				filter = StringTools.replace(filter, " ", "");
				JNI.callMember(JNI.createMemberMethod('org/haxe/lime/FileDialog', 'openMultiple', '(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V'), JNI_FILE_DIALOG, [filter, defaultPath, title]);
				return true;

			case OPEN_DIRECTORY:
				// JNI.callMember(JNI.createMemberMethod('org/haxe/lime/FileDialog', 'openDocumentTree', '(Ljava/lang/String;)V'), JNI_FILE_DIALOG, [null]);
				onCancel.dispatch();
				return false;

			case SAVE:
				// save(null, filter, defaultPath, title, 'application/octet-stream');
				onCancel.dispatch();
				return false;
		}
		return true;
		#elseif ios
		switch (type)
		{
			case OPEN:
				NativeCFFI.lime_file_dialog_browse_select_ios(native_id);
				return true;
			case OPEN_MULTIPLE:
				NativeCFFI.lime_file_dialog_browse_select_multiple_ios(native_id);
				return true;
			default:
				onCancel.dispatch();
				return false;
		}
		#else
		onCancel.dispatch();
		return false;
		#end
	}

	/**
		Shows an open file dialog. If successful, `onOpen` will trigger with the file contents.

		This function only works on desktop targets, and will return `false` otherwise.
		@param filter 		A filter to use when browsing. Asterisks are treated as wildcards. For example,
		`"*.jpg"` will match any file ending in `.jpg`.
		@param defaultPath 	The directory in which to start browsing and/or the default filename to
		suggest. Defaults to `Sys.getCwd()`, with no default filename.
		@param title 		The title to give the dialog window.
		@return Whether `open()` is supported on this target.
	**/
	public function open(filter:String = null, defaultPath:String = null, title:String = null):Bool
	{
		#if (desktop && sys)
		var worker = new BackgroundWorker();

		worker.doWork.add(function(_)
		{
			#if linux
			if (title == null) title = "Open File";
			#end

			var path = null;
			#if (!macro && lime_cffi)
			#if hl
			var bytes = NativeCFFI.lime_file_dialog_open_file(title, filter, defaultPath);
			if (bytes != null) path = @:privateAccess String.fromUTF8(cast bytes);
			#else
			path = NativeCFFI.lime_file_dialog_open_file(title, filter, defaultPath);
			#end
			#end

			worker.sendComplete(path);
		});

		worker.onComplete.add(function(path:String)
		{
			if (path != null)
			{
				try
				{
					var data = File.getBytes(path);
					onOpen.dispatch(data);
					return;
				}
				catch (e:Dynamic) {}
			}

			onCancel.dispatch();
		});

		worker.run();

		return true;
		#elseif android
		filter = StringTools.replace(filter, " ", "");
		JNI.callMember(JNI.createMemberMethod('org/haxe/lime/FileDialog', 'open', '(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V'), JNI_FILE_DIALOG, [filter, defaultPath, title]);
		return true;
		#elseif ios
		NativeCFFI.lime_file_dialog_open_ios(native_id);
		return true;
		#else
		onCancel.dispatch();
		return false;
		#end
	}

	/**
		Shows an open file dialog. If successful, `onSave` will trigger with the selected path.

		This function only works on desktop and HMTL5 targets, and will return `false` otherwise.
		@param data 		The file contents, in `haxe.io.Bytes` format. (Implicit casting possible.)
		@param filter 		A filter to use when browsing. Asterisks are treated as wildcards. For example,
		`"*.jpg"` will match any file ending in `.jpg`. Used only if targeting deskop.
		@param defaultPath 	The directory in which to start browsing and/or the default filename to
		suggest. When targeting destkop, this defaults to `Sys.getCwd()` with no default filename. When targeting
		HTML5, this defaults to the browser's download directory, with a default filename based on the MIME type.
		@param title 		The title to give the dialog window.
		@param type 		The default MIME type of the file, in case the type can't be determined from the
		file data. Used only if targeting Android or HTML5.
		@return Whether `save()` is supported on this target.
	**/
	public function save(data:Resource, filter:String = null, defaultPath:String = null, title:String = null, type:String = "application/octet-stream"):Bool
	{
		#if !android
		if (data == null)
		{
			onCancel.dispatch();
			return false;
		}
		#end

		#if (desktop && sys)
		var worker = new BackgroundWorker();

		worker.doWork.add(function(_)
		{
			#if linux
			if (title == null) title = "Save File";
			#end

			var path = null;
			#if (!macro && lime_cffi)
			#if hl
			var bytes = NativeCFFI.lime_file_dialog_save_file(title, filter, defaultPath);
			path = @:privateAccess String.fromUTF8(cast bytes);
			#else
			path = NativeCFFI.lime_file_dialog_save_file(title, filter, defaultPath);
			#end
			#end

			worker.sendComplete(path);
		});

		worker.onComplete.add(function(path:String)
		{
			if (path != null)
			{
				try
				{
					File.saveBytes(path, data);
					onSave.dispatch(path);
					return;
				}
				catch (e:Dynamic) {}
			}

			onCancel.dispatch();
		});

		worker.run();

		return true;
		#elseif (js && html5)
		// TODO: Cleaner API for mimeType detection

		var defaultExtension = "";

		if (Image.__isPNG(data))
		{
			type = "image/png";
			defaultExtension = ".png";
		}
		else if (Image.__isJPG(data))
		{
			type = "image/jpeg";
			defaultExtension = ".jpg";
		}
		else if (Image.__isGIF(data))
		{
			type = "image/gif";
			defaultExtension = ".gif";
		}
		else if (Image.__isWebP(data))
		{
			type = "image/webp";
			defaultExtension = ".webp";
		}

		var path = defaultPath != null ? Path.withoutDirectory(defaultPath) : "download" + defaultExtension;
		var buffer = (data : Bytes).getData();
		buffer = buffer.slice(0, (data : Bytes).length);

		#if commonjs
		untyped #if haxe4 js.Syntax.code #else __js__ #end ("require ('file-saver')")(new Blob([buffer], {type: type}), path, true);
		#else
		untyped window.saveAs(new Blob([buffer], {type: type}), path, true);
		#end
		onSave.dispatch(path);
		return true;
		#elseif android
		if (Image.__isPNG(data))
		{
			type = "image/png";
		}
		else if (Image.__isJPG(data))
		{
			type = "image/jpeg";
		}
		else if (Image.__isGIF(data))
		{
			type = "image/gif";
		}
		else if (Image.__isWebP(data))
		{
			type = "image/webp";
		}
		var bytes:Bytes = data;
		var path:String = defaultPath == null ? null : Path.directory(defaultPath);
		var defaultName:String = defaultPath == null ? null : Path.withoutDirectory(defaultPath);
		JNI.callMember(JNI.createMemberMethod('org/haxe/lime/FileDialog', 'save', '([BLjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V'),
			JNI_FILE_DIALOG, [bytes == null ? null : bytes.getData(), type, path, defaultName]);
		return true;
		#else
		onCancel.dispatch();
		return false;
		#end
	}

	#if android
	@:runOnMainThread
	@:keep
	private function onJNIActivityResult(requestCode:Int, resultCode:Int, uri:String, path:String)
	{
		// trace('onJNIActivityResults: requestCode: ${Std.string(requestCode)}, resultCode: ${Std.string(resultCode)}, uri: $uri, path: $path');

		if (resultCode == RESULT_OK)
		{
			switch (requestCode)
			{
				case OPEN_REQUEST_CODE:
					try
					{
						if (IS_SELECT)
							onSelect.dispatch(path);
						else
							onOpen.dispatch(File.getBytes(path));
					}
					catch (e:Dynamic)
					{
						if (IS_SELECT)
							trace('Failed to dispatch onSelect: $e');
						else
							trace('Failed to dispatch onOpen: $e');
					}
				case OPEN_MULTIPLE_REQUEST_CODE:
					try
					{
						var paths:Array<String> = StringTools.contains(path, ",") ? path.split(',') : [path];
						if (paths == null || paths.contains(null) || paths.length <= 0) throw "Got null paths array";
						onSelectMultiple.dispatch(paths);
					}
					catch (e:Dynamic)
					{
						trace('Failed to dispatch onSelectMultiple: $e');
					}
				case SAVE_REQUEST_CODE:
					try
					{
						if (IS_SELECT)
							onSelect.dispatch(path);
						else
							onSave.dispatch(path);
					}
					catch (e:Dynamic)
					{
						if (IS_SELECT)
							trace('Failed to dispatch onSelect: $e');
						else
							trace('Failed to dispatch onSave: $e');
					}
				case DOCUMENT_TREE_REQUEST_CODE:
					trace("Directory select doesn't work yet.");
					onCancel.dispatch();
					// try
					// {
					// 	onSelect.dispatch(uri);
					// }
					// catch (e:Dynamic)
					// {
					// 	trace('Failed to dispatch onSelect: $e');
					// }
			}
		}
		else
			onCancel.dispatch();
		IS_SELECT = false;
	}
	#end
}

#if ios
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.ui.FileDialog)
private class FileDialogEventHanlder
{
	public var fileDialogEventInfo:FileDialogEventInfo;

	public function new()
	{
		fileDialogEventInfo = new FileDialogEventInfo(FILE_DIALOG_EVENT, "", -1);
		NativeCFFI.lime_file_dialog_manager_register_ios(handleFileDialogEvent, fileDialogEventInfo);
	}

	private function handleFileDialogEvent():Void
	{
		if (!FileDialog.fileDialogInstances.exists(fileDialogEventInfo.id)) return;
		
		var FileDialogInstance = FileDialog.fileDialogInstances.get(fileDialogEventInfo.id);
		var file:String = fileDialogEventInfo.file;

		switch (fileDialogEventInfo.type)
		{
			case FILE_OPEN_SUCCESS:
				FileDialogInstance.onOpen.dispatch(File.getBytes(file));
			case FILE_BROWSE_SELECT:
				FileDialogInstance.onSelect.dispatch(file);
			case FILE_BROWSE_SELECT_MULTIPLE:
				FileDialogInstance.onSelectMultiple.dispatch(file.split(','));
			case FILE_OPEN_ERROR | FILE_OPEN_CANCELED | FILE_SAVE_CANCELED | FILE_SAVE_ERROR:
				FileDialogInstance.onCancel.dispatch();
			default:
		}
	}
}

@:keep
private class FileDialogEventInfo
{
	public var id:Int;
	public var file:String;
	public var type:FileDialogEventType;

	public function new(type:FileDialogEventType = null, file:String, id:Int)
	{
		this.type = type;
	}

	public function clone():FileDialogEventInfo
	{
		return new FileDialogEventInfo(type, file, id);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract FileDialogEventType(Int)
{
	var FILE_OPEN_SUCCESS = 0;
	var FILE_OPEN_CANCELED = 1;
	var FILE_OPEN_ERROR = 2;
	var FILE_BROWSE_SELECT = 3;
	var FILE_BROWSE_SELECT_MULTIPLE = 4;
	var FILE_SAVE_SUCCESS = 5;
	var FILE_SAVE_CANCELED = 6;
	var FILE_SAVE_ERROR = 7;
	var FILE_DIALOG_EVENT = 8;
}
#end