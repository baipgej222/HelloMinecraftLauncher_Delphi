unit UFrmDownload;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, XPMan, IdAntiFreezeBase, IdAntiFreeze,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP;

type
  TForm1 = class(TForm)
    IdHTTP1: TIdHTTP;
    IdAntiFreeze1: TIdAntiFreeze;
    Label1: TLabel;
    Edit_Url: TEdit;
    XPManifest1: TXPManifest;
    ProgressBar1: TProgressBar;
    Btn_Start: TButton;
    Btn_Stop: TButton;
    Label2: TLabel;
    Label3: TLabel;
    Lab_Size: TLabel;
    Label5: TLabel;
    Lab_CurNum: TLabel;
    ListBox1: TListBox;
    Lab_Over: TLabel;
    procedure Btn_StartClick(Sender: TObject);
    procedure IdHTTP1Status(ASender: TObject; const AStatus: TIdStatus;
      const AStatusText: String);
    procedure Btn_StopClick(Sender: TObject);
    procedure IdHTTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCountMax: Integer);
    procedure FormCreate(Sender: TObject);
    procedure IdHTTP1WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
    procedure IdHTTP1Work(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCount: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
    function GetURLFileName(aURL: string): string;  //�������ص�ַ���ļ���
    procedure DownFile(fileUrl:string); //�����ļ�����
  end;

var
  Form1: TForm1;
  startIndex:Integer;
  IsStop:Boolean;       //�û��Ƿ���ֹ
implementation

{$R *.dfm}
procedure TForm1.FormCreate(Sender: TObject);
begin
  self.Lab_Over.Caption:='';
end;


function TForm1.GetURLFileName(aURL: string): string;
var
  i: integer;
  s: string;
begin
  s := aURL;
  i := Pos('/', s);
  while i <> 0 do //ȥ��"/"ǰ�������ʣ�µľ����ļ�����
  begin
    Delete(s, 1, i);
    i := Pos('/', s);
  end;
  Result := s;
end;

//��ʼ����
procedure TForm1.Btn_StartClick(Sender: TObject);
begin
  IsStop:=false;  //�û��Ƿ���ֹ
  DownFile(self.Edit_Url.Text);
end;

//ֹͣ
procedure TForm1.Btn_StopClick(Sender: TObject);
begin
  self.Lab_Over.Caption:='������ֹ����...';
  Application.ProcessMessages;
  IsStop:=true;//�û��Ƿ���ֹ
end;

//����״̬
procedure TForm1.IdHTTP1Status(ASender: TObject; const AStatus: TIdStatus;
  const AStatusText: String);
begin
  ListBox1.ItemIndex := ListBox1.Items.Add(AStatusText);
end;

//�����ļ�����
procedure TForm1.DownFile(fileUrl: string);
var
  fileName:string;
  tStream: TFileStream;
begin
  fileName:=self.GetURLFileName(fileUrl); //������·���л�ȡ�ļ���

  if FileExists(fileName) then            //����ļ��Ѿ�����
    tStream := TFileStream.Create(fileName, fmOpenWrite)
  else
    tStream := TFileStream.Create(fileName, fmCreate);

  if FileExists(fileName)=false then      //��������
  begin
    IdHTTP1.Request.ContentRangeStart:=0; //��ָ���ļ�ƫ�ƴ����������ļ�
    startIndex:=0;
  end
  else begin                              //����
    startIndex:=tStream.Size-1;
    if startIndex < 0 then startIndex:=0;
    IdHTTP1.Request.ContentRangeStart := startIndex;
    tStream.Position := startIndex ;      //�ƶ�������������
    idhttp1.HandleRedirects := true;
    IdHTTP1.Head(fileUrl);                //����HEAD����
  end;

  try
    self.IdHTTP1.Get(fileUrl,tStream);
  except
  end;

  tStream.Free;
end;

//׼�������ļ�
procedure TForm1.IdHTTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCountMax: Integer);
begin
  self.Lab_Over.Caption:='��������...';
  self.Lab_Size.Caption:=IntToStr(AWorkCountMax+startIndex)+'KB';
  self.Lab_CurNum.Caption:='0KB';
  self.ProgressBar1.Min:=0;
  self.ProgressBar1.Max:=AWorkCountMax+startIndex;
  self.ProgressBar1.Position:=0;
  self.Btn_Stop.Enabled:=true;  //ֹͣ��ť����
  self.Btn_Start.Enabled:=false;//��ʼ��ť����
end;


//�������ӽ���
procedure TForm1.IdHTTP1WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
begin
  if IsStop then
    self.Lab_Over.Caption:='�����ѱ���ֹ!'
  else
    self.Lab_Over.Caption:='�������!';

  self.Btn_Stop.Enabled:=false;  //ֹͣ��ť����
  self.Btn_Start.Enabled:=true;  //��ʼ��ť����
end;

//�ļ�������
procedure TForm1.IdHTTP1Work(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCount: Integer);
begin
  if IsStop then //�û��Ƿ���ֹ
  begin
      self.IdHTTP1.Disconnect;
  end;

  self.Lab_CurNum.Caption:=IntToStr(AWorkCount+startIndex)+'KB';
  ProgressBar1.Position := AWorkCount+startIndex;
end;

end.
