unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ufrmdrag;

type
  TfrmMain = class(TfrmDrag)
    GroupBox1: TGroupBox;
    Edit1: TEdit;
    Button1: TButton;
    GroupBox2: TGroupBox;
    ListView1: TListView;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    Edit2: TEdit;
    Label2: TLabel;
    Edit3: TEdit;
    Label3: TLabel;
    Edit4: TEdit;
    GroupBox4: TGroupBox;
    Label5: TLabel;
    Edit5: TEdit;
    Label6: TLabel;
    Edit6: TEdit;
    Label7: TLabel;
    Edit7: TEdit;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    OpenDialog1: TOpenDialog;
    Edit8: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    procedure DoDragDropFile(sPath: string); override;
    procedure LoadFile(sPath: string);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

type
  Section = record
    sName: string; //��������
    VSize: Cardinal; //����ʵ��ӳ�����ڴ��������ռ�õĳߴ�
    VAddress: Cardinal; //����ӳ�����ڴ���RVA��ַ
    ROffset: Cardinal; //�������ļ��е�ƫ��
    RSize: Cardinal; //�������ļ��ж����ĳߴ�
  end;

var
  outFile: file of Byte;
  stSection: array of Section;

function ReadDWORD(iSeek: Cardinal): Cardinal; //��ָ��λ�ö�ȡһ��DWORD
var
  bBuf: array[0..3] of Byte;
begin
  try
    Seek(outFile, iSeek);
    read(outFile, bBuf[0], bBuf[1], bBuf[2], bBuf[3]);
    Move(bBuf, Result, 4);
  except
    on EInOutError do
      ShowMessage('�ļ���ȡ���ִ���');
    else
      raise;
  end;
end;

function ReadWORD(iSeek: Cardinal): Word; //��ָ��λ�ö�ȡһ��WORD
var
  bBuf: array[0..1] of Byte;
begin
  try
    Seek(outFile, iSeek);
    read(outFile, bBuf[0], bBuf[1]);
    Move(bBuf, Result, 2);
  except
    on EInOutError do
      ShowMessage('�ļ���ȡ���ִ���');
    else
      raise;
  end;
end;

function ReadString(iSeek: Cardinal): string; //��ָ��λ�ö���һ��8BYTE��ANSI�ַ���
var
  sStr: string;
  bCh: Byte;
begin
  try
    Seek(outFile, iSeek);
    read(outFile, bCh);
    while bCh <> 0 do
    begin
      sStr := sStr + Char(bCh);
      read(outFile, bCh);
    end;
    Result := sStr;
  except
    on EInOutError do
      ShowMessage('�ļ���ȡ���ִ���');
    else
      raise;
  end;
end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    Edit1.Text := OpenDialog1.FileName;
    LoadFile(Edit1.Text);
  end;
end;

procedure TfrmMain.LoadFile(sPath: string);
var
  iPe: Cardinal; //PEͷ�Ŀ�ʼ��ַ
  iSection: Cardinal; //���α�Ŀ�ʼ��ַ
  iSecCount: Cardinal; //������Ŀ
  i: Cardinal;
begin
  AssignFile(outFile, Edit1.Text);
  FileMode := fmOpenRead;
  Reset(outFile);
  iPe := ReadDWORD($3C); //��ȡPE�ļ�ͷ���ļ��е�λ��
  Edit2.Text := '$' + IntToHex(ReadDWORD(iPe + $34), 4); //��ȡImageBase�ֶ�
  Edit3.Text := '$' + IntToHex(ReadDWORD(iPe + $38), 4); //��ȡ�������ڴ��еĶ���ֵ
  Edit4.Text := '$' + IntToHex(ReadDWORD(iPe + $3C), 4); //��ȡ�������ļ��еĶ���ֵ
  iSection := iPe + $18 + ReadWORD(iPe + $14); //ȡ���α������ļ�ƫ��
  iSecCount := ReadWORD(iPe + $6); //��ȡ������Ŀ
  SetLength(stSection, iSecCount);
  for i := 0 to iSecCount - 1 do //ѭ����ȡ��������
  begin
    stSection[i].sName := ReadString(iSection + 40 * i); //��ȡ��������
    stSection[i].VAddress := ReadDWORD(iSection + 40 * i + 12); //��ȡ����ӳ����RVA��ַ
    stSection[i].RSize := ReadDWORD(iSection + 40 * i + 16); //��ȡ���ξ����ļ������ĳߴ�
    stSection[i].ROffset := ReadDWORD(iSection + i * 40 + 20); //��ȡ�������ļ��е�ƫ�Ƶ�ַ
    stSection[i].VSize := ((stSection[i].RSize div Cardinal(StrToInt(Edit3.Text))) + 1) * Cardinal(StrToInt(Edit3.Text));
    //��ȡ�������ڴ��ж����ĳߴ�
  end;
  ListView1.Clear;
  for i := Low(stSection) to High(stSection) do //��ʾ��ȡ��������������
  begin
    with ListView1.Items.Add do
    begin
      Caption := stSection[i].sName;
      SubItems.Add(IntToHex(stSection[i].VSize, 4));
      SubItems.Add(IntToHex(stSection[i].VAddress, 4));
      SubItems.Add(IntToHex(stSection[i].ROffset, 4));
      SubItems.Add(IntToHex(stSection[i].RSize, 4));
    end;
  end;
  CloseFile(outFile); //�ر��ļ�
end;


procedure TfrmMain.Button2Click(Sender: TObject);
var
  i: Integer;
  iOffset: Cardinal;
  k: Cardinal;
  iBase: Cardinal;
begin
  iOffset := StrToInt('$' + Edit5.Text);
  iBase := StrToInt(Edit2.Text); //ȡ��ӳ�����ַ
  for i := Low(stSection) to High(stSection) do
  begin
    if (iOffset >= stSection[i].ROffset) and (iOffset <= stSection[i].ROffset + stSection[i].RSize) then
    begin
      k := stSection[i].VAddress - stSection[i].ROffset;
      Edit6.Text := IntToHex(k + iOffset, 8); //�ó�RVA��ַ
      Edit7.Text := IntToHex(k + iOffset + iBase, 8); //�ó�VA��ַ
      Edit8.Text := stSection[i].sName;
      Exit;
    end;
  end;
  Edit5.Text := '';
  Edit6.Text := '';
  Edit7.Text := '';
  ShowMessage('ת��ʧ�ܣ�');
end;

procedure TfrmMain.Button3Click(Sender: TObject);
var
  i: Integer;
  iRVA: Cardinal;
  k: Cardinal;
  iBase: Cardinal;
begin
  iBase := StrToInt(Edit2.Text); //ȡ��ӳ�����ַ
  iRVA := StrToInt('$' + Edit6.Text);
  for i := Low(stSection) to High(stSection) do
  begin
    if (iRVA >= stSection[i].VAddress) and (iRVA <= stSection[i].VAddress + stSection[i].RSize) then
    begin
      k := stSection[i].VAddress - stSection[i].ROffset;
      Edit5.Text := IntToHex(iRVA - k, 8);
      Edit7.Text := IntToHex(iRVA + iBase, 8);
      Edit8.Text := stSection[i].sName;
      Exit;
    end;
  end;
  Edit5.Text := '';
  Edit6.Text := '';
  Edit7.Text := '';
  ShowMessage('ת��ʧ�ܣ�');
end;

procedure TfrmMain.Button4Click(Sender: TObject);
var
  iBase: Cardinal;
begin
  iBase := StrToInt(Edit2.Text); //ȡ��ӳ�����ַ
  Edit6.Text := IntToHex(Cardinal(StrToInt('$' + Edit7.Text)) - iBase, 8);
  Button3.Click;
end;

procedure TfrmMain.DoDragDropFile(sPath: string);
begin
  Edit1.Text := sPath;
  LoadFile(sPath);
end;

end.
