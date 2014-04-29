unit UHTTPGetThread;
//Download by http://www.codefans.net
interface
uses classes, SysUtils, wininet, windows;


type
  TOnProgressEvent = procedure(TotalSize, Readed: Integer) of object;


  THTTPGetThread = class(TThread)

  private
    FTAcceptTypes: string; //�����ļ����� *.*
    FTAgent: string; //�������  Nokia6610/1.0 (5.52) Profile/MIDP-1.0 Configuration/CLDC-1.02
    FTURL: string; // url
    FTFileName: string; //�ļ���
    FTStringResult: AnsiString;
    FTUserName: string; //�û���
    FTPassword: string; //����
    FTPostQuery: string; //������,post����get
    FTReferer: string;
    FTBinaryData: Boolean;
    FTUseCache: Boolean; //�Ƿ�ӻ��������
    FTMimeType: string; //Mime����

    FTResult: Boolean;
    FTFileSize: Integer;
    FTToFile: Boolean; //�Ƿ��ļ�

    BytesToRead,
      BytesReaded: LongWord;

    FTProgress: TOnProgressEvent;

    procedure ParseURL(URL: string; var HostName, FileName: string; var portNO: integer); //ȡ��url�����������ļ���
    procedure UpdateProgress;
    procedure setResult(FResult: boolean);
    function getResult(): boolean;
  protected
    procedure Execute; override;
  public

    function getFileName(): string;
    function getToFile(): boolean;
    function getFileSize(): integer;
    function getStringResult(): AnsiString;
    constructor Create(aAcceptTypes, aMimeType, aAgent, aURL, aFileName, aUserName, aPassword, aPostQuery, aReferer: string; aBinaryData, aUseCache: Boolean; aProgress: TOnProgressEvent; aToFile: Boolean);
  published
    property BResult: boolean read getResult write setResult;
  end;

implementation

{ THTTPGetThread }

constructor THTTPGetThread.Create(aAcceptTypes, aMimeType, aAgent, aURL, aFileName, aUserName, aPassword, aPostQuery, aReferer: string; aBinaryData, aUseCache: Boolean; aProgress: TOnProgressEvent; aToFile: Boolean);
begin
  FreeOnTerminate := True;
  inherited Create(True);

  FTAcceptTypes := aAcceptTypes;
  FTAgent := aAgent;
  FTURL := aURL;
  FTFileName := aFileName;
  FTUserName := aUserName;
  FTPassword := aPassword;
  //FTPostQuery := aPostQuery;
  FTPostQuery := StringReplace(aPostQuery, #13#10, '', [rfReplaceAll]);
  FTStringResult := '';
  FTReferer := aReferer;
  FTProgress := aProgress;
  FTBinaryData := aBinaryData;
  FTUseCache := aUseCache;
  FTMimeType := aMimeType;
  FTResult := false;
  FTToFile := aToFile;
  FTFileSize := 0;
  Resume;
end;

procedure THTTPGetThread.Execute;
var
  hSession: hInternet; //�ػ����
  hConnect: hInternet; //���Ӿ��
  hRequest: hInternet; //������
  Host_Name: string; //������
  File_Name: string; //�ļ���
  port_no: integer;

  RequestMethod: PChar;
  InternetFlag: longWord;
  AcceptType: PAnsiChar;
  dwBufLen, dwIndex: longword;
  Buf: Pointer; //������
  f: file;
  Data: array[0..$400] of Char;
  TempStr: AnsiString;
  mime_Head: string;

  procedure CloseHandles;
  begin
    InternetCloseHandle(hRequest);
    InternetCloseHandle(hConnect);
    InternetCloseHandle(hSession);
  end;

begin
  inherited;
  buf := nil;
  try
    try
      ParseURL(FTURL, Host_Name, File_Name, port_no);

      if Terminated then begin
        FTResult := False;
        Exit;
      end;
     //�����Ự
      hSession := InternetOpen(pchar(FTAgent), //lpszCallerNameָ������ʹ�����纯����Ӧ�ó���
        INTERNET_OPEN_TYPE_PRECONFIG, //����dwAccessTypeָ����������
        nil, //����������lpszProxyName���� accesstypeΪGATEWAY_PROXY_INTERNET_ACCESS��CERN_PROXY_ACCESSʱ
        nil, //NProxyPort��������CERN_PROXY_INTERNET_ACCESS������ָ��ʹ�õĶ˿�����ʹ��INTERNET_INVALID_PORT_NUMBER�൱���ṩȴʡ�Ķ˿�����
        0); //���ö����ѡ�������ʹ��INTERNET_FLAG_ASYNC��־ȥָʾʹ�÷��ؾ����Ľ�����Internet������Ϊ�ص���������״̬��Ϣ��ʹ��InternetSetStatusCallback���д�������

     //��������
      hConnect := InternetConnect(hSession, //�Ự���
        PChar(Host_Name), //ָ�����Internet���������������ƣ���http://www.mit.edu����IP��ַ����202.102.13.141�����ַ���
        port_no, //INTERNET_DEFAULT_HTTP_PORT, //�ǽ�Ҫ���ᵽ��TCP/IP�Ķ˿ں�
        PChar(FTUserName), //�û���
        PChar(FTPassword), //����
        INTERNET_SERVICE_HTTP, //Э��
        0, // ��ѡ��ǣ�����ΪINTERNET_FLAG_SECURE����ʾʹ��SSL/PCTЭ���������
        0); //Ӧ�ó������ֵ������Ϊ���صľ����ʶӦ�ó����豸����

      if FTPostQuery = '' then RequestMethod := 'GET'
      else RequestMethod := 'POST';

      if FTUseCache then InternetFlag := 0
      else InternetFlag := INTERNET_FLAG_RELOAD;

      AcceptType := PAnsiChar('Accept: ' + FTAcceptTypes);

    //����һ��http������
      hRequest := HttpOpenRequest(hConnect, //InternetConnect���ص�HTTP�Ự���
        RequestMethod, //ָ����������ʹ�õ�"����"���ַ������������ΪNULL����ʹ��"GET"
        PChar(File_Name), //ָ��������ʵ�Ŀ��������Ƶ��ַ�����ͨ�����ļ����ơ���ִ��ģ�������˵����
        'HTTP/1.0', //ָ�����HTTP�汾���ַ��������ΪNULL����Ĭ��Ϊ"HTTP/1.0"��
        PChar(FTReferer), //ָ������ĵ���ַ��URL�����ַ����������URL�����ǴӸ��ĵ���ȡ��
        @AcceptType, //ָ��ͻ����յ����ݵ�����
        InternetFlag,
        0);
      mime_Head := 'Content-Type: ' + FTMimeType;
      if FTPostQuery = '' then
        FTResult := HttpSendRequest(hRequest, nil, 0, nil, 0)
      else
    //����һ��ָ������httpserver
        FTResult := HttpSendRequest(hRequest,
          pchar(mime_Head), //mime ͷ
          length(mime_Head), //ͷ����
          PChar(FTPostQuery), //�������ݻ���������Ϊ��
          strlen(PChar(FTPostQuery))); //�������ݻ���������

      if Terminated then
      begin
      //CloseHandles;
        FTResult := False;
        Exit;
      end;

      dwIndex := 0;
      dwBufLen := 1024;
      GetMem(Buf, dwBufLen);

    //����header��Ϣ��һ��http����
      FTResult := HttpQueryInfo(hRequest,
        HTTP_QUERY_CONTENT_LENGTH,
        Buf, //ָ��һ������������Ϣ�Ļ�������ָ��
        dwBufLen, //HttpQueryInfo���ݵĴ�С
        dwIndex); //��ȡ���ֽ���

      if Terminated then begin
        FTResult := False;
        Exit;
      end;

      if FTResult or not FTBinaryData then begin //�������
        if FTResult then
          FTFileSize := StrToInt(string(StrPas(PAnsiChar(Buf))));

        BytesReaded := 0;

        if FTToFile then begin
          AssignFile(f, FTFileName);
          Rewrite(f, 1);
        end else FTStringResult := '';

        while True do begin
          if Terminated then begin
            FTResult := False;
            Exit;
          end;

          if not InternetReadFile(hRequest,
            @Data, //��������
            SizeOf(Data), //��С
            BytesToRead) //��ȡ���ֽ���
            then Break
          else
            if BytesToRead = 0 then Break
            else begin
              if FTToFile then
                BlockWrite(f, Data, BytesToRead) //������������д���ļ�
              else begin
                TempStr := Data;
                SetLength(TempStr, BytesToRead);
                FTStringResult := FTStringResult + TempStr;
              end;

              inc(BytesReaded, BytesToRead);

              if Assigned(FTProgress) then //ִ�лص�����
                Synchronize(UpdateProgress);

            end;
        end;

        if FTToFile then
          FTResult := FTFileSize = Integer(BytesReaded)
        else begin
         // SetLength(FTStringResult, BytesReaded);
          FTResult := BytesReaded <> 0;
        end;

      end;
    except
    end;
  finally
    if FTToFile then CloseFile(f);

    if assigned(Buf) then FreeMem(Buf);
    CloseHandles;
  end;
end;



function THTTPGetThread.getFileName: string;
begin
  result := FTFileName;
end;

function THTTPGetThread.getFileSize: integer;
begin
  result := FTFileSize;
end;

function THTTPGetThread.getResult: boolean;
begin
  result := FTResult;
end;

function THTTPGetThread.getStringResult: AnsiString;
begin
  result := FTStringResult;
end;

function THTTPGetThread.getToFile: boolean;
begin
  result := FTToFile;
end;

procedure THTTPGetThread.ParseURL(URL: string; var HostName, FileName: string; var portNO: integer);
var
  i: Integer;
begin
  if Pos('http://', LowerCase(URL)) <> 0 then
    Delete(URL, 1, 7);

  i := Pos('/', URL);
  HostName := Copy(URL, 1, i);
  FileName := Copy(URL, i, Length(URL) - i + 1);

  i := pos(':', hostName);
  if i <> 0 then begin
    portNO := strtoint(copy(hostName, i + 1, length(hostName) - i - 1));
    hostName := copy(hostName, 1, i - 1);
  end else portNO := 80;

  if (Length(HostName) > 0) and (HostName[Length(HostName)] = '/') then SetLength(HostName, Length(HostName) - 1);
end;


procedure THTTPGetThread.setResult(FResult: boolean);
begin
  FTResult := FResult;
end;

procedure THTTPGetThread.UpdateProgress;
begin
  FTProgress(FTFileSize, BytesReaded);
end;

end.

