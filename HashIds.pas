unit HashIds;

interface

const
  minAlphabetLength = 16;
  cAlphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
  cSeps = 'cfhistuCFHISTU';
  guardDiv = 12;

type

  TIDs = array of Integer;

  THashIds = class(TObject)
    private
      Alphabet      : string;
      Salt          : string;
      MinHashLength : Integer;
      Separators    : string;
      Guards        : string;
      function Hash(const Input : Integer; const HashStr : string) : string;
      function Unhash(const Input,HashStr : string) : Integer;
      function ConsistentShuffle(const Value,Shuffle : string) : string;
      function Encode(Numbers : TIDs) : string;
      function Decode(const Hash : string) : TIDs;
    public
      function Encrypt(Id : Integer) : string; overload;
      function Encrypt(CommaSeperatedIds : string) : string; overload;
      function Encrypt(Numbers : TIDs) : string; overload;
      function Decrypt(Value : string) : TIDs;
      function DecryptToStr(Value : string) : string;
      constructor Create(Salt : string = ''; MinHashLength : Integer = 0; Alphabet : string = '');
      destructor Destroy; override;
  end;

implementation

uses Classes,SysUtils,Math;

constructor THashIds.Create(Salt : string = ''; MinHashLength : Integer = 0; Alphabet : string = '');
var
  s : string;
  n : Integer;
begin
  inherited Create;
  if Length(Salt) = 0
  then Self.Salt:=''
  else Self.Salt:=Salt;

  Self.MinHashLength:=MinHashLength;

  if Length(Alphabet) = 0
  then Self.Alphabet:=cAlphabet
  else Self.Alphabet:=Salt;

  Self.Separators:=cSeps;

    // Remove duplicate characters from alphabet
  s:='';
  for n:=1 to Length(Self.Alphabet) do
    if pos(Self.Alphabet[n],s) = 0 then s:=s + Self.Alphabet[n];
  Self.Alphabet:=s;
  if pos(' ',Self.Alphabet) > 0 then raise Exception.Create('error: alphabet cannot contain spaces');
  if Length(Self.Alphabet) < minAlphabetLength then raise Exception.Create('"error: alphabet must contain at least ' + IntToStr(minAlphabetLength) + ' unique characters');

    // Separators should NOT contain only characters present in alphabet
  s:='';
  for n:=1 to Length(Self.Separators) do
    if pos(Self.Separators[n],Self.Alphabet) > 0 then
        s:=s + Self.Separators[n];
  Self.Separators:=s;

    // alphabet should contain NOT characters present in Separators
  s:='';
  for n:=1 to Length(Self.Alphabet) do
    if pos(Self.Alphabet[n],Self.Separators) = 0 then
        s:=s + Self.Alphabet[n];
  Self.Alphabet:=s;
    // Shuffel Separators
  Self.Separators:=ConsistentShuffle(Self.Separators,Self.Salt);
    // Shuffel Alphabet

  Self.Alphabet:=ConsistentShuffle(Self.Alphabet,Self.Salt);
  n:=Round(Length(Self.Alphabet) / guardDiv);
  if Length(Self.Alphabet) < 3 then
  begin
    Self.Guards:=Copy(Self.Separators,1,n);
    Self.Separators:=Copy(Self.Separators,n + 1);
  end
  else
  begin
    Self.Guards:=Copy(Self.Alphabet,1,n);
    Self.Alphabet:=Copy(Self.Alphabet,n + 1);
  end;
end;

destructor THashIds.Destroy;
begin
  inherited Destroy;
end;

function THashIds.Encrypt(CommaSeperatedIds : string) : string;
var
  nums : TIDs;
  list : TStringList;
  n    : Integer;
begin
  list:=TStringList.Create;
  try
    list.CommaText:=CommaSeperatedIds;
    if list.Count = 0 then Exit;
    SetLength(nums,list.Count);
    for n:=0 to list.Count - 1 do
    begin
      try
        nums[n]:=StrToInt(list[n])
      except
        on E : Exception do
        begin
          raise Exception.Create('Error where convering string "' + list[n] + '" to a number: ' + E.Message);
        end;
      end;
      if nums[n] < 0 then raise Exception.Create('Id must be greather or equal to zero');
    end;
  finally
    list.Free;
  end;
  Result:=Encode(nums);
end;

function THashIds.Encrypt(Id : Integer) : string;
var
  num : TIDs;
begin
  Result:='';
  SetLength(num,1);
  num[Low(num)]:=Id;
  Result:=Encode(num);
end;

function THashIds.Encrypt(Numbers : TIDs) : string;
begin
  Result:=Encode(Numbers);
end;

function THashIds.Decrypt(Value : string) : TIDs;
begin
  SetLength(Result,0);
  if Value = '' then Exit;
  Result:=Decode(Value);
end;

function THashIds.DecryptToStr(Value : string) : string;
var
  Ids: TIDs;
  n: Integer;
begin
  Result:='';
  Ids:=Decrypt(Value);
  for n:= Low(Ids) to High(Ids) do
  begin
    if n > 0  then Result:=Result+',';
    Result:=Result+IntToStr(Ids[n]);
  end;

end;

function THashIds.Encode(Numbers : TIDs) : string;
var
  n              : Integer;
  numbersHashInt : Integer;
  sAlphabet      : string;
  sLottery       : string;
  Last           : string;
begin
  sAlphabet:=Self.Alphabet;
  numbersHashInt:=0;

  for n:=Low(Numbers) to High(Numbers) do numbersHashInt:=numbersHashInt+(Numbers[n] mod (n + 100));
  sLottery:=sAlphabet[(numbersHashInt mod Length(sAlphabet)) + 1]; // Delphi string start at 1 not at 0
  Result:=sLottery;
  for n:=Low(Numbers) to High(Numbers) do
  begin
    sAlphabet:=ConsistentShuffle(sAlphabet,sLottery + Self.Salt + sAlphabet);
    Last:=Hash(Numbers[n],sAlphabet);
    Result:=Result + Last;
    if (n < High(Numbers)) then
        Result:=Result+Self.Separators[((Numbers[n] mod (Ord(Last[1])+n)) mod Length(Self.Separators))+1];
  end;

  if Length(Result) < Self.MinHashLength then
  begin
    Result:=Self.Guards[((numbersHashInt+Ord(Result[1])) mod Length(Self.Guards))+1]+Result;
    if Length(Result) < Self.MinHashLength then
        Result:=Result+Self.Guards[((numbersHashInt+Ord(Result[3])) mod Length(Self.Guards))+1];
    n:=Length(sAlphabet) div 2;
    while (Length(Result) < Self.MinHashLength) do
    begin
      sAlphabet:=ConsistentShuffle(sAlphabet,sAlphabet);
      Result:=Copy(sAlphabet,n+1)+Result+Copy(sAlphabet,1,n);
      if Length(Result) > Self.MinHashLength then
      begin
        Result:=Copy(Result,((Length(Result)-Self.MinHashLength) div 2)+1,Self.MinHashLength);
      end;
    end;
  end;
end;

function THashIds.Decode(const Hash : string) : TIDs;
var
  sAlphabet : string;
  sLottery  : string;
  n         : Integer;
  HashList  : TStringList;
  s         : string;
begin
  SetLength(Result,0);
  s:=Hash;
  for n:=1 to Length(Self.Guards) do s:=StringReplace(s,Self.Guards[n],',',[rfReplaceAll]);
  sAlphabet:=Self.Alphabet;
  HashList:=TStringList.Create;
  try
    HashList.CommaText:=s;
    if HashList.Count > 1
    then s:=HashList[1]
    else s:=Hash;
    HashList.Clear;
    for n:=1 to Length(Self.Separators) do s:=StringReplace(s,Self.Separators[n],',',[rfReplaceAll]);
    HashList.CommaText:=s;
    if HashList.Count = 0 then Exit;
    sLottery:=HashList[0][1];
    HashList[0]:=Copy(HashList[0],2);
    SetLength(Result,HashList.Count);
    for n:=0 to HashList.Count - 1 do
    begin
      sAlphabet:=ConsistentShuffle(sAlphabet,sLottery+Self.Salt+sAlphabet);
      Result[n]:=Unhash(HashList[n],sAlphabet);
    end;
    if Encode(Result) <> Hash then
      SetLength(Result, 0);
  finally
    HashList.Free;
  end;
end;

function THashIds.Hash(const Input : Integer; const HashStr : string) : string;
var
  n              : Integer;
  alphabetLength : Integer;
begin
  Result:='';
  n:=Input;
  alphabetLength:=Length(HashStr);
  repeat
    Result:=HashStr[(n mod alphabetLength)+1]+Result;
    n:=n div alphabetLength;
  until n = 0;
end;

function THashIds.Unhash(const Input : String; const HashStr : string) : Integer;
var
  n : Integer;
begin
  Result:=0;
  for n:=1 to Length(Input) do
      Result:=Result + (pos(Input[n],HashStr) - 1)*Round(Power(Length(HashStr),Length(Input)-n));
end;

function THashIds.ConsistentShuffle(const Value,Shuffle : string) : string;
var
  i,v,p,j,n : Integer;
  k         : Char;
begin
  Result:=Value;
  if Length(Shuffle) = 0 then Exit;
  i:=Length(Value) - 1;
  v:=0;
  p:=0;
  while i > 0 do
  begin
    v:=v mod Length(Shuffle);
    n:=Ord(Shuffle[v + 1]);
    p:=p+n;
    j:=(n+v+p) mod i;
    k:=Result[j+1];
    Result:=Copy(Result,1,j)+Result[i + 1]+Copy(Result,j + 2);
    Result:=Copy(Result,1,i)+k+Copy(Result,i + 2);
    Dec(i);
    Inc(v);
  end;
end;

end.

