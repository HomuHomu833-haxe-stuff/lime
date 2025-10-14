#ifndef LIME_UI_FILE_DIALOG_H
#define LIME_UI_FILE_DIALOG_H


#include <string>
#include <vector>
#include <ui/FileDialogEvent.h>


#ifdef IPHONE
#ifdef __OBJC__
@class FileDialogObserver;
#else
typedef struct objc_object FileDialogObserver;
#endif
#endif
namespace lime {


	class FileDialog {

		public:
			#ifdef IPHONE
			static int Create();
			static void Open (int id_handle);
			static void BrowseSelect (int id_handle);
			static void BrowseSelectMultiple (int id_handle);
			static void LaunchFileDialogOpen(FileDialogObserver *observer, bool selectMultiple);
			// static std::wstring* OpenDirectory (std::wstring* title = 0, std::wstring* filter = 0, std::wstring* defaultPath = 0);
			// static void OpenFiles (std::vector<std::wstring*>* files, std::wstring* title = 0, std::wstring* filter = 0, std::wstring* defaultPath = 0);
			// static std::wstring* SaveFile (std::wstring* title = 0, std::wstring* filter = 0, std::wstring* defaultPath = 0);
			#else
			static std::wstring* OpenDirectory (std::wstring* title = 0, std::wstring* filter = 0, std::wstring* defaultPath = 0);
			static std::wstring* OpenFile (std::wstring* title = 0, std::wstring* filter = 0, std::wstring* defaultPath = 0);
			static void OpenFiles (std::vector<std::wstring*>* files, std::wstring* title = 0, std::wstring* filter = 0, std::wstring* defaultPath = 0);
			static std::wstring* SaveFile (std::wstring* title = 0, std::wstring* filter = 0, std::wstring* defaultPath = 0);
			#endif
	};


}


#endif