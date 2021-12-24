unit Helper.Classes;

interface
  uses
    System.Classes,
    System.SysUtils,
    System.Rtti,
    System.TypInfo,
    System.Variants;

type
  TObjectHelper = class helper for TObject
  public
    function GetValue(APropertyName: String): TValue;
    function HasProperty(APropertyName: String): Boolean;
    function IsEnumeration(APropertyName: String): Boolean;
    function IsBoolean(APropertyName: String): Boolean;
    procedure SetValue(APropertyName: string; AValue: TValue);
    function ValueAsString(const AValue: string): string;
  end;

type
  TValueHelper = record helper for TValue
  public
    function AsBoolNativeInt(const ATrueStr: string = 'S'): NativeInt;
  end;

implementation

function TObjectHelper.GetValue(APropertyName: String): TValue;
var
  eContext  : TRttiContext;
  eProperty : TRttiProperty;
begin
  Result := Nil;
  eContext := TRttiContext.create;
  try
    eProperty := eContext.GetType(Self.ClassType).GetProperty(APropertyName);

    if Assigned(eProperty) then
      Result := eProperty.GetValue(Self)
    else
      raise Exception.Create(APropertyName + ' inválido para valor de dados.' );
  finally
    eContext.Free;
  end;
end;

function TObjectHelper.HasProperty(APropertyName: String): Boolean;
var
  eContext  : TRttiContext;
  eProperty : TRttiProperty;
begin
  eContext := TRttiContext.create;
  try
    eProperty := eContext.GetType(Self.ClassType).GetProperty(APropertyName);
    Result := Assigned(eProperty)
  finally
    eContext.Free;
  end;
end;

function TObjectHelper.IsBoolean(APropertyName: String): Boolean;
var
  eContext  : TRttiContext;
  eProperty : TRttiProperty;
begin
  Result := False;
  eContext := TRttiContext.create;
  try
    eProperty := eContext.GetType(Self.ClassType).GetProperty(APropertyName);
    if Assigned(eProperty) then
      Result := CompareText(eProperty.PropertyType.Name, 'Boolean') = 0;
  finally
    eContext.Free;
  end;
end;

function TObjectHelper.IsEnumeration(APropertyName: String): Boolean;
var
  eContext  : TRttiContext;
  eProperty : TRttiProperty;
begin
  Result := False;
  eContext := TRttiContext.create;
  try
    eProperty := eContext.GetType(Self.ClassType).GetProperty(APropertyName);
    if Assigned(eProperty) then
      Result := eProperty.PropertyType.TypeKind = tkEnumeration;
  finally
    eContext.Free;
  end;
end;

procedure TObjectHelper.SetValue(APropertyName: string; AValue: TValue);
var
  eContext  : TRttiContext;
  eProperty : TRttiProperty;
  ePropInfo : PPropInfo;
  eValue    : TValue;
begin
  eContext := TRttiContext.create;
  try
    eProperty := eContext.GetType(Self.ClassType).GetProperty(APropertyName);

    if Assigned(eProperty) then
    begin
      case eProperty.PropertyType.TypeKind of
        tkString,
        tkChar,
        tkWChar,
        tkLString,
        tkWString,
        tkUString : eProperty.SetValue(Self, AValue.AsString);
        tkInteger,
        tkInt64   :
        begin
          if AValue.Kind in [tkString, tkChar, tkWChar, tkLString, tkWString, tkUString] then
          begin
            if AValue.AsString.IsEmpty then
              eProperty.SetValue(Self, 0)
            else
              eProperty.SetValue(Self, AValue.AsString.ToInteger);
          end
          else
            eProperty.SetValue(Self, AValue.AsInteger);
        end;
        tkFloat   :
        begin
          if AValue.ToString.IsEmpty then
            Exit;
          if CompareText(eProperty.PropertyType.Name, 'TDateTime') = 0 then
            eValue := StrToDate(AValue.AsString)
          else if CompareText(eProperty.PropertyType.Name, 'TTime') = 0 then
            eValue := StrToTime(AValue.AsString)
          else
            eValue := TValue.From(AValue.AsExtended);

          eProperty.SetValue(Self, eValue);
        end;
        tkEnumeration:
        begin
          ePropInfo := GetPropInfo(Self.ClassInfo, APropertyName);
          if ePropInfo <> nil then
          begin
            if CompareText(eProperty.PropertyType.Name, 'Boolean') = 0 then
              SetOrdProp(Self, ePropInfo, AValue.AsBoolNativeInt)
            else
              SetOrdProp(Self, ePropInfo, AValue.AsInteger);
          end;
        end
        else
          eProperty.SetValue(Self, AValue);
      end;
    end
    else
      raise Exception.Create(APropertyName + ' inválido para valor de dados.' );

  finally
    eContext.Free;
  end;
end;

function TObjectHelper.ValueAsString(const AValue: string): string;
var
  APropertyValue: TValue;
begin
  if not Self.HasProperty(AValue) then
    Exit('');

  APropertyValue := Self.GetValue(AValue);

  case APropertyValue.TypeInfo.Kind  of
    tkInteger, tkInt64:
      Result := IntToStr(APropertyValue.AsInteger);
    tkString, tkLString, tkWString,tkWChar, tkChar, tkUString:
      Result := APropertyValue.AsString;
    tkFloat:
    begin
      if APropertyValue.TypeInfo.Name = 'TDateTime' then
        Result := DateToStr(APropertyValue.AsExtended)
      else
        Result := FloatToStr(APropertyValue.AsCurrency);
    end;
  end;
end;

function TValueHelper.AsBoolNativeInt(const ATrueStr: string = 'S'): NativeInt;
begin
  if Self.AsString = ATrueStr then
    Result := 1
  else
    Result := 0;
end;

end.
