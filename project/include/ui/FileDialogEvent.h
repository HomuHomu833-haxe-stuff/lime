#ifndef LIME_UI_FILE_DIALOG_EVENT_H
#define LIME_UI_FILE_DIALOG_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {


	enum FileDialogEventType {

		FILE_OPEN_SUCCESS,
		FILE_OPEN_CANCELED,
		FILE_OPEN_ERROR,
		FILE_BROWSE_SELECT,
		FILE_BROWSE_SELECT_MULTIPLE,
		FILE_SAVE_SUCCESS,
		FILE_SAVE_CANCELED,
		FILE_SAVE_ERROR,
		FILE_DIALOG_EVENT

	};


	struct FileDialogEvent {

		hl_type* t;
		int id;
		vbyte* file;
		FileDialogEventType type;

		static ValuePointer* callback;
		static ValuePointer* eventObject;

		FileDialogEvent ();

		static void Dispatch (FileDialogEvent* event);

	};


}


#endif