@echo off
chcp 65001 > nul
set "folder=%~1"
if "%folder%"=="" set "folder=%cd%"

:: 使用PowerShell方案（优先）
where powershell >nul 2>&1
if %errorlevel% equ 0 (
    for /f "delims=" %%a in ('powershell -Command "$totalSize = 0; Get-ChildItem -Path '%folder%' -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $totalSize += $_.Length }; $totalSize" 2^>nul') do (
        echo %%a
        exit /b 0
    )
)

:: JScript备用方案
echo 正在使用JScript替代方案...
(
echo // JSON polyfill
echo if(typeof JSON==="undefined"){JSON={};}
echo (function(){function f(n){return n<10?"0"+n:n;}
echo function this_value(){return this.valueOf();}
echo Date.prototype.toJSON=function(){return isFinite(this.valueOf())?this.getUTCFullYear()+"-"+f(this.getUTCMonth()+1)+"-"+f(this.getUTCDate())+"T"+f(this.getUTCHours())+":"+f(this.getUTCMinutes())+":"+f(this.getUTCSeconds())+"Z":null;};
echo var cx=/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,escapable=/[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,gap,indent,meta={"\b":"\\b","\t":"\\t","\n":"\\n","\f":"\\f","\r":"\\r",'"':'\\"',"\\":"\\\\"},rep;
echo function quote(string){escapable.lastIndex=0;return escapable.test(string)?'"'+string.replace(escapable,function(a){var c=meta[a];return typeof c==="string"?c:"\\u"+("0000"+a.charCodeAt(0).toString(16)).slice(-4);})+'"':'"'+string+'"';}
echo function str(key,holder){var i,k,v,length,mind=gap,partial,value=holder[key];if(value&&typeof value==="object"&&typeof value.toJSON==="function"){value=value.toJSON(key);}if(typeof rep==="function"){value=rep.call(holder,key,value);}
echo switch(typeof value){case"string":return quote(value);case"number":return isFinite(value)?String(value):"null";case"boolean":case"null":return String(value);case"object":if(!value){return"null";}gap+=indent;partial=[];
echo if(Object.prototype.toString.apply(value)==="[object Array]"){length=value.length;for(i=0;i<length;i+=1){partial[i]=str(i,value)||"null";}
echo v=partial.length===0?"[]":gap?"[\n"+gap+partial.join(",\n"+gap)+"\n"+mind+"]":"["+partial.join(",")+"]";gap=mind;return v;}
echo if(rep&&typeof rep==="object"){length=rep.length;for(i=0;i<length;i+=1){if(typeof rep[i]==="string"){k=rep[i];v=str(k,value);if(v){partial.push(quote(k)+(gap?": ":":")+v);}}}}else{for(k in value){if(Object.prototype.hasOwnProperty.call(value,k)){v=str(k,value);if(v){partial.push(quote(k)+(gap?": ":":")+v);}}}}
echo v=partial.length===0?"{}":gap?"{\n"+gap+partial.join(",\n"+gap)+"\n"+mind+"}":"{"+partial.join(",")+"}";gap=mind;return v;}};JSON.stringify=function(value,replacer,space){var i;gap="";indent="";
echo if(typeof space==="number"){for(i=0;i<space;i+=1){indent+=" ";}}else if(typeof space==="string"){indent=space;}
echo rep=replacer;if(replacer&&typeof replacer!=="function"&&(typeof replacer!=="object"||typeof replacer.length!=="number")){throw new Error("JSON.stringify");}
echo return str("",{"":value});};})();

echo // 主逻辑
echo var totalSize = 0;
echo var fso = new ActiveXObject("Scripting.FileSystemObject");
echo function scanFolder(folderPath) {
echo    try {
echo        var folder = fso.GetFolder(folderPath);
echo        var fc = new Enumerator(folder.Files);
echo        for (; !fc.atEnd(); fc.moveNext()) {
echo            var file = fc.item();
echo            totalSize += file.Size;
echo        }
echo        var subfolders = new Enumerator(folder.SubFolders);
echo        for (; !subfolders.atEnd(); subfolders.moveNext()) {
echo            scanFolder(subfolders.item().Path);
echo        }
echo    } catch(e) { /* 忽略错误 */ }
echo }
echo scanFolder("%folder%");
echo WScript.Echo(totalSize);
) > "%temp%\filesize.js"

for /f "delims=" %%a in ('cscript //nologo //E:JScript "%temp%\filesize.js" 2^>nul') do (
    echo %%a
)
del "%temp%\filesize.js" 2>nul
exit /b