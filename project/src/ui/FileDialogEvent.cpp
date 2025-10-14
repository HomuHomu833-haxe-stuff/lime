#include <system/CFFI.h>
#include <system/OrientationEvent.h>
#include <ui/FileDialogEvent.h>


namespace lime {


	lime::ValuePointer* FileDialogEvent::callback = 0;
	lime::ValuePointer* FileDialogEvent::eventObject = 0;

	static int id_type;
	static int id_file;
	static int id_id;
	static bool init = false;


	FileDialogEvent::FileDialogEvent () {

		file = nullptr;
		type = FILE_DIALOG_EVENT;
		id = -1;

	}


	void FileDialogEvent::Dispatch (FileDialogEvent* event) {

		if (FileDialogEvent::callback) {

			if (FileDialogEvent::eventObject->IsCFFIValue ()) {

				if (!init) {

					id_file = val_id ("file");
					id_type = val_id ("type");
					id_id = val_id("id");
					init = true;

				}

				value object = (value)FileDialogEvent::eventObject->Get ();

				alloc_field (object, id_file, alloc_string ((const char*)event->file));
				alloc_field (object, id_type, alloc_int (event->type));
				alloc_field (object, id_id, alloc_int (event->id));

			} else {

				FileDialogEvent* eventObject = (FileDialogEvent*)FileDialogEvent::eventObject->Get ();
				
				int length = strlen ((const char*)event->file);
				char* file = (char*)malloc (length + 1);
				strcpy (file, (const char*)event->file);
				eventObject->file = (vbyte*)file;
				eventObject->type = event->type;
				eventObject->id = event->id;

			}

			FileDialogEvent::callback->Call ();

		}

	}

}
