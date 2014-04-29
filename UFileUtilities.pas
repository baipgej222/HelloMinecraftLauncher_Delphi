unit UFileUtilities;

interface

uses Classes, SysUtils, Forms, Dialogs, WinApi.Windows, VCLZip;

type
  TFileUtilities = class
  public
    class function FindAllDirectory(InDirectory:String):TStringList;static;
    class function FindAllFiles(InDirectory:String):TStringList;static;
    class function Zip(ZipMode, PackSize:Integer; ZipFile, UnzipDir: String):Boolean; static;
    class function ExtractLastDirectory(Dir:string):String;
    class function IsSeparator(ch:char):boolean;static;
    class function RemoveLastSeparator(Dir:string):string;
    class function ReadToEnd(fileName:String):string;
    class function AddSeparator(st:String):String;
    class procedure WriteToFile(fileName, content:String);
    class function CopyDir(sDirName, sToDirName:String):Boolean;
    class procedure DeleteDir(sDirectory:String);

    class function CurrentDir:String;
  end;

implementation

class function TFileUtilities.CurrentDir:String;
begin
  exit(ExtractFilePath(Application.ExeName));
end;

class function TFileUtilities.IsSeparator(ch: Char):Boolean;
begin
  exit((ch = '/') or (ch = '\'));
end;

class function TFileUtilities.RemoveLastSeparator(Dir:string):string;
var ch:char;
begin
  Dir := Trim(Dir);
  ch := Dir[length(Dir)];
  if IsSeparator(ch) then
    delete(Dir, length(Dir), 1);
  exit(Dir);
end;

class function TFileUtilities.FindAllDirectory(InDirectory:String):TStringList;
var
SR: TSearchRec;
begin
  FindAllDirectory := TStringList.Create;
  if InDirectory[Length(InDirectory)] <> '\' then
  InDirectory := InDirectory + '\';
  if FindFirst(InDirectory+'*.*', FADirectory, SR) = 0 then
  repeat
     if (SR.Attr and FADirectory) <> 0 then
     if (SR.Name <> '.') and (SR.Name <> '..') then
     begin
       FindAllDirectory.Add(SR.Name);
     end;
     Application.ProcessMessages;
  until FindNext(SR) <> 0;
  SysUtils.FindClose(SR);
end;

class function TFileUtilities.FindAllFiles(InDirectory:String):TStringList;
var
SR: TSearchRec;
begin
  FindAllFiles := TStringList.Create;
  if InDirectory[Length(InDirectory)] <> '\' then
  InDirectory := InDirectory + '\';
  if FindFirst(InDirectory+'*.*', FaAnyFile, SR) = 0 then
  repeat
     if (SR.Attr and FADirectory) = 0 then
      FindAllFiles.Add(sr.Name);
     Application.ProcessMessages;
  until FindNext(SR) <> 0;
  SysUtils.FindClose(SR);
end;

class function TFileUtilities.Zip(ZipMode,PackSize:Integer;ZipFile,UnzipDir:String):Boolean; //ѹ�����ѹ���ļ�
var ziper:TVCLZip;
begin
  //�����÷���Zip(ѹ��ģʽ��ѹ������С��ѹ���ļ�����ѹĿ¼)
  //ZipModeΪ0��ѹ����Ϊ1����ѹ�� PackSizeΪ0�򲻷ְ�������Ϊ�ְ��Ĵ�С
  try
    if copy(UnzipDir, length(UnzipDir), 1) = '\' then
      UnzipDir := copy(UnzipDir, 1, length(UnzipDir) - 1); //ȥ��Ŀ¼��ġ�\��
    ziper:=TVCLZip.Create(application); //����zipper
    ziper.DoAll:=true; //�Ӵ����ý��Էְ��ļ���ѹ����Ч
    //ziper.OverwriteMode:=TUZOverwriteMode.Always; //���Ǹ���ģʽ
    if PackSize<>0 then begin //���Ϊ0��ѹ����һ���ļ�������ѹ�ɶ��ļ�
      //ziper.MultiZipInfo.MultiMode:=TMultiMode.mmBlocks; //���÷ְ�ģʽ
      ziper.MultiZipInfo.SaveZipInfoOnFirstDisk:=True; //�����Ϣ�����ڵ�һ�ļ���
      ziper.MultiZipInfo.FirstBlockSize:=PackSize; //�ְ����ļ���С
      ziper.MultiZipInfo.BlockSize:=PackSize; //�����ְ��ļ���С
    end;
    ziper.FilesList.Clear;
    ziper.ZipName := ZipFile; //��ȡѹ���ļ���
    if ZipMode=0 then begin //ѹ���ļ�����
      ziper.FilesList.Add(UnzipDir+'\*.*'); //��ӽ�ѹ���ļ��б�
      Application.ProcessMessages; //��ӦWINDOWS�¼�
      ziper.Zip; //ѹ��
    end else begin
      ziper.DestDir:= UnzipDir; //��ѹ����Ŀ��Ŀ¼
      ziper.UnZip; //��ѹ��
    end;
    ziper.Free; //�ͷ�ѹ��������Դ
    Result:=True; //ִ�гɹ�
  except
    Result:=False;//ִ��ʧ��
  end;
end;

class function TFileUtilities.AddSeparator(st:string):string;
begin
  st := Trim(st);
  if st[length(st)] = '\' then
    exit(st)
  else
    exit(st+'\');
end;

class function TFileUtilities.ExtractLastDirectory(Dir: string): string;
var i:integer;
begin
  Dir := TFileUtilities.RemoveLastSeparator(Dir);
  i := length(Dir);
  while (i >= 1) and (Not IsSeparator(Dir[i]))  do
  begin
    Dec(i);
  end;
  if i <= 0 then raise Exception.Create('Error Path');
  exit(copy(Dir, i + 1, length(Dir) - i))
end;

function AnsiStringToWideString(const ansi: AnsiString): WideString;
var len:Integer;
begin
  Result := '';
  if ansi = '' then exit;
  len := MultiByteToWideChar(936, MB_PRECOMPOSED, @ansi[1], -1, nil, 0);
  SetLength(result, len - 1);
  if Len > 1 then
    MultiByteToWideChar(936, MB_PRECOMPOSED, @ansi[1], -1, PWideChar(@result[1]), len - 1);
end;

class function TFileUtilities.ReadToEnd(fileName: String): string;
var f: TextFile; j: String;
begin
  if not fileexists(fileName) then
    result := ''
  else
  begin
    AssignFile(f, fileName);
    ReSet(f);
    while not eof(f) do
    begin
      readln(f, j); result := result + j;
    end;
    CloseFile(f);
  end;
end;

class procedure TFileUtilities.WriteToFile(fileName, content: string);
var f: TextFile;
begin
  ForceDirectories(ExtractFilePath(fileName));
  AssignFile(f, fileName);
  Rewrite(f);
  Writeln(f,content);
  CloseFile(f);
end;

class function TFileUtilities.CopyDir(sDirName:String;sToDirName:String):Boolean;
var
hFindFile:Cardinal;
t,tfile:String;
sCurDir:String[255];
FindFileData:WIN32_FIND_DATA;
begin
  //��¼��ǰĿ¼
  sCurDir:=GetCurrentDir;
  ChDir(sDirName);
  hFindFile:=FindFirstFile('*.*',FindFileData);
  if hFindFile<>INVALID_HANDLE_VALUE then
  begin
    if not DirectoryExists(sToDirName) then
    ForceDirectories(sToDirName);
    repeat
      tfile:=FindFileData.cFileName;
      if (tfile='.') or (tfile='..') then
        continue;
      if FindFileData.dwFileAttributes = FILE_ATTRIBUTE_DIRECTORY then
      begin
        t:=sToDirName+'\'+tfile;
        if not DirectoryExists(t) then
          ForceDirectories(t);
        if sDirName[Length(sDirName)]<>'\' then
          CopyDir(sDirName+'\'+tfile,t)
        else
          CopyDir(sDirName+tfile,sToDirName+tfile);
      end
      else
      begin
        t:=sToDirName+'\'+tFile;
        CopyFile(PChar(tfile),PChar(t),True);
      end;
    until FindNextFile(hFindFile,FindFileData)=false;
    /// FindClose(hFindFile);
  end
  else
  begin
    ChDir(sCurDir);
    result:=false;
    exit;
  end;
  //�ص���ǰĿ¼
  ChDir(sCurDir);
  result:=true;
end;

class procedure TFileUtilities.DeleteDir(sDirectory:String);
var
  sr:TSearchRec;
  sPath,sFile:String;
begin
  //���Ŀ¼�������Ƿ���'\'
  if Copy(sDirectory,Length(sDirectory),1)<>'\'then
    sPath:=sDirectory+'\'
  else
    sPath:=sDirectory;
  //------------------------------------------------------------------
  if FindFirst(sPath+'*.*',faAnyFile,sr)=0 then
  begin
    repeat
      sFile:=Trim(sr.Name);
      if sFile='.' then Continue;
      if sFile='..' then Continue;
      sFile:=sPath+sr.Name;
      if(sr.Attr and faDirectory)<>0 then
        DeleteDir(sFile)
      else if(sr.Attr and faAnyFile)=sr.Attr then
        DeleteFile(PWideChar(WideString(sFile)));//ɾ���ļ�
    until FindNext(sr)<>0;
    SysUtils.FindClose(sr);
  end;
  RemoveDir(sPath);
end;

end.
