# Flutter install නොකර Windows EXE එක ලබාගැනීම

## 1. GitHub account සහ repository එක

1. https://github.com වෙත ගොස් account එකක් සාදන්න හෝ login වෙන්න.
2. ඉහළ දකුණු පැත්තේ `+` > **New repository** තෝරන්න.
3. Repository name ලෙස `smart-school-transport-manager` යොදන්න.
4. **Private** තෝරන්න.
5. **Create repository** ඔබන්න.

## 2. Project files upload කිරීම

1. මෙම ZIP එක extract කරන්න.
2. Extract කළ `smart_school_transport_flutter` folder එක විවෘත කරන්න.
3. GitHub repository එකේ **uploading an existing file** තෝරන්න.
4. Folder එක නොව, folder එක ඇතුළේ තිබෙන සියලු files/folders upload කරන්න.
5. `.github` folder එකද upload වී ඇති බව තහවුරු කරන්න.
6. පහළ **Commit changes** ඔබන්න.

Browser upload එක hidden `.github` folder එක නොපෙන්වන්නේ නම් GitHub Desktop භාවිතා
කරන්න, නැත්නම් `.github/workflows/build-windows.yml` file එක GitHub website එකෙන්
අතින් create කරන්න.

## 3. Build එක ආරම්භ කිරීම

1. Repository එකේ **Actions** tab එකට යන්න.
2. වම් පැත්තේ **Build Windows App** තෝරන්න.
3. **Run workflow** > **Run workflow** ඔබන්න.
4. Build එක අවසන් වන තෙක් විනාඩි 10–20 පමණ රැඳී සිටින්න.

## 4. Installer එක download කිරීම

1. කොළ පාට tick එක සහිත build run එක විවෘත කරන්න.
2. පහළ **Artifacts** කොටසට යන්න.
3. `Smart-School-Transport-Manager-Windows` download කරන්න.
4. Download වූ ZIP එක extract කරන්න.
5. `Smart_School_Transport_Manager_Setup.exe` double-click කර install කරන්න.

`Smart_School_Transport_Manager_Portable.zip` භාවිතා කළොත් install නොකරම app
එක run කළ හැකියි. ZIP එක සම්පූර්ණයෙන් extract කර EXE එක open කරන්න.

## වැදගත්

- GitHub Actions build කිරීමේදී ඔයාගේ PC එකට Flutter හෝ Visual Studio අවශ්‍ය නැහැ.
- Private repository එකක් භාවිතා කරන්න; bundled database එකේ business data තිබිය හැකියි.
- GitHub artifact download link එක දින 30කට පසු ඉවත් විය හැකියි. Installer එක වෙනම save කරගන්න.
