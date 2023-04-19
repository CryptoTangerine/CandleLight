unit Unit1;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  System.Rtti,
  FMX.Grid.Style,
  FMX.ScrollBox,
  FMX.Grid,
  FMX.Memo.Types,
  FMX.Memo, FMX.Menus;

type
  candle = record
    time: string;
    open: Double;
    high: Double;
    low: Double;
    close: Double;
  end;

  TCandleSet = array[0..4] of candle;

  TScenario = record
    m1_candles, m5_candles, m15_candles, hourly_candles: TCandleSet;
  end;

type
  TForm1 = class(TForm)
    Button1: TButton;
    StringGrid1: TStringGrid;
    StringColumn1: TStringColumn;
    StringColumn2: TStringColumn;
    StringColumn3: TStringColumn;
    StringColumn4: TStringColumn;
    StringColumn5: TStringColumn;
    Memo1: TMemo;
    Timer1: TTimer;
    PopupMenu1: TPopupMenu;
    MenuItem1: TMenuItem;
    MenuItem_sounds_enabled: TMenuItem;
    MenuItem_M1_sounds: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem_loop_enabled: TMenuItem;
    Panel1: TPanel;
    MenuItem2: TMenuItem;
    MenuItem_stay_on_top: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem_engulf_all_3: TMenuItem;
    MenuItem_engulf_wick: TMenuItem;
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure MenuItem_loop_enabledClick(Sender: TObject);
    procedure MenuItem_sounds_enabledClick(Sender: TObject);
    procedure MenuItem_stay_on_topClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Cycle;
    procedure Push_to_grid(row,col:integer; candleSet: TCandleSet; symbol,timeframe:string);
  end;

var Form1: TForm1;

implementation

{$R *.fmx}

procedure Log(msg:string);
begin
  form1.Memo1.Lines.Add(msg);
end;

function parse_csv_file(filename: string): TScenario;
const
  candles_in_a_set = 5;
var
  c: candle;
begin
  var csv := TStringList.Create;
  var row := TStringlist.Create;
  row.StrictDelimiter:= true;

  try
    csv.LoadFromFile(filename);
  except
    on EFOpenError do
      begin
        //Log('Trying to open file being written into by python, skip');
        exit;
      end;
  end;

  for var i := csv.Count - 1 downto 1 do
    if csv[i].IsEmpty then
      csv.Delete(i);

  for var i := 1 to csv.Count - 1 do
    begin
      row.DelimitedText:= csv[i];
      //time,open,high,low,close,volume

      c.time  := row[0];
      c.open  := StrToFloat(row[1]);
      c.high  := StrToFloat(row[2]);
      c.low   := StrToFloat(row[3]);
      c.close := StrToFloat(row[4]);
      //c.volume := StrToFloat(row[5]);

      var candle_index:= (i-1) mod candles_in_a_set;
      case i of
        1..5:   result.m1_candles     [candle_index] := c;
        6..10:   result.m5_candles     [candle_index] := c;
        11..15:  result.m15_candles    [candle_index] := c;
        16..20: result.hourly_candles [candle_index] := c;
      end;
    end;

  csv.Free;
  row.Free;
end;

procedure Breakpoint;
begin

end;

function BullishEngulfing(candleSet: TCandleSet): Boolean;
var
  prev_candle_boundary: double;
begin
  var starting_index:= 0;
  var prevCandle3:=   candleSet[starting_index];
  var prevCandle2:=   candleSet[starting_index+1];
  var prevCandle1:=   candleSet[starting_index+2];
  var currentCandle:= candleSet[starting_index+3];
  var bear1:= prevCandle1.close < prevCandle1.open;
  var bear2:= prevCandle2.close < prevCandle2.open;
  var bear3:= prevCandle3.close < prevCandle3.open;
  if Form1.MenuItem_engulf_all_3.IsChecked then
    prev_candle_boundary:= prevCandle3.open
  else
    if Form1.MenuItem_engulf_wick.IsChecked then
      prev_candle_boundary:= prevCandle1.high
    else
      prev_candle_boundary:= prevCandle1.open;
  var bull_engulf:= (currentCandle.close > currentCandle.open) and
            (currentCandle.close > prev_candle_boundary);
  var bear_sequence:= bear1 and bear2 and bear3;
  Result := bear_sequence and bull_engulf;
  if result then
    Breakpoint;
end;

function BearishEngulfing(candleSet: TCandleSet): Boolean;
var
  prev_candle_boundary: double;
begin
  var starting_index:= 0;
  var prevCandle3:=   candleSet[starting_index];
  var prevCandle2:=   candleSet[starting_index+1];
  var prevCandle1:=   candleSet[starting_index+2];
  var currentCandle:= candleSet[starting_index+3];
  var bull1:= prevCandle1.close > prevCandle1.open;
  var bull2:= prevCandle2.close > prevCandle2.open;
  var bull3:= prevCandle3.close > prevCandle3.open;
  if Form1.MenuItem_engulf_all_3.IsChecked then
    prev_candle_boundary:= prevCandle3.open
  else
    if Form1.MenuItem_engulf_wick.IsChecked then
      prev_candle_boundary:= prevCandle1.low
    else
      prev_candle_boundary:= prevCandle1.open;
  var bear_engulf:= (currentCandle.close < currentCandle.open) and
            (currentCandle.close < prev_candle_boundary);
  var bull_sequence:= bull1 and bull2 and bull3;
  Result := bull_sequence and bear_engulf;
  if result then
    Breakpoint;
end;

procedure TForm1.Push_to_grid(row,col:integer; candleSet: TCandleSet; symbol,timeframe:string);
begin
  var bull:= BullishEngulfing(candleSet);
  var bear:= BearishEngulfing(candleSet);

  if bull and bear then
    raise Exception.Create('Cannot have both bull and bear');

  var previous_value:= StringGrid1.Cells[col,row];

  if not bull and not bear then
    StringGrid1.Cells[col,row]:= '';
  if bull then
    StringGrid1.Cells[col,row]:= 'BULL';
  if bear then
    StringGrid1.Cells[col,row]:= 'BEAR';

  var new_value:= StringGrid1.Cells[col,row];
  if new_value.IsEmpty then exit;

  if new_value <> previous_value then
    begin
      Log(formatdatetime('c',now) +' '+ symbol +' '+ timeframe +' '+ new_value);

      if not MenuItem_sounds_enabled.IsChecked then exit;
      if (timeframe='M1') and not MenuItem_M1_sounds.IsChecked then exit;

      beep;
    end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Cycle;
end;

procedure TForm1.Cycle;
begin
  for var I := 1 to 7 do
    begin
      var symbol:= StringGrid1.Cells[0, I];
      var scenario:= parse_csv_file(symbol+'_ohlc_data.txt');

      Push_to_grid(I,1,scenario.m1_candles,     symbol,'M1');
      Push_to_grid(I,2,scenario.m5_candles,     symbol,'M5');
      Push_to_grid(I,3,scenario.m15_candles,    symbol,'M15');
      Push_to_grid(I,4,scenario.hourly_candles, symbol,'H1');
    end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  popup_point: TPointF;
begin
  // Calculate the position of the popup based on the form position and button offset
  popup_point.X := Form1.Left + Button1.Position.X + Button1.Width;
  popup_point.Y := Form1.Top  + Button1.Position.Y + Button1.Height;

  PopupMenu1.Popup(popup_point.X,popup_point.Y);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  StringGrid1.RowCount := 8; // 7 data rows + 1 header row
  StringGrid1.Cells[0, 0] := 'DXY (future)';
  StringGrid1.Cells[0, 1] := 'AUDUSD';
  StringGrid1.Cells[0, 2] := 'EURUSD';
  StringGrid1.Cells[0, 3] := 'GBPUSD';
  StringGrid1.Cells[0, 4] := 'NZDUSD';
  StringGrid1.Cells[0, 5] := 'USDCAD';
  StringGrid1.Cells[0, 6] := 'USDCHF';
  StringGrid1.Cells[0, 7] := 'USDJPY';

  if not FileExists('AUDUSD_ohlc_data.txt') then
    begin
      Log('Cannot start, OHLC data not found in the folder');
      Log('Make sure the python script is running');
      exit;
    end;

  Timer1.Enabled:= true;
  MenuItem_loop_enabled.IsChecked:= true;
  Log('Main loop started with 1s frequency');
  beep;
end;

procedure TForm1.MenuItem_loop_enabledClick(Sender: TObject);
begin
  var value:= not MenuItem_loop_enabled.IsChecked;
  MenuItem_loop_enabled.IsChecked:= value;
  Timer1.Enabled:= value;
  Log('Main loop enabled: '+BoolToStr(value,true));
end;

procedure TForm1.MenuItem_sounds_enabledClick(Sender: TObject);
begin
  var value:= not MenuItem_sounds_enabled.IsChecked;
  MenuItem_sounds_enabled.IsChecked:= value;
  Log('Sounds enabled: '+BoolToStr(value,true));
end;

procedure TForm1.MenuItem_stay_on_topClick(Sender: TObject);
begin
  var value:= not MenuItem_stay_on_top.IsChecked;
  MenuItem_stay_on_top.IsChecked:= value;
  Log('Stay-on-top enabled: '+BoolToStr(value,true));

  if value then
    form1.FormStyle:= TFormStyle.StayOnTop
  else
    form1.FormStyle:= TFormStyle.Normal;
end;

end.
