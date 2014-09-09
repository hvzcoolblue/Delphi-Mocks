{***************************************************************************}
{                                                                           }
{           Delphi.Mocks                                                    }
{                                                                           }
{           Copyright (C) 2011 Vincent Parrett                              }
{                                                                           }
{           http://www.finalbuilder.com                                     }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

unit Delphi.Mocks.MethodData;

{$I 'Delphi.Mocks.inc'}


interface

uses
  Rtti,
  SysUtils,
  Generics.Collections,
  Delphi.Mocks,
  Delphi.Mocks.Interfaces,
  Delphi.Mocks.ParamMatcher;

type
  TMethodData = class(TInterfacedObject,IMethodData)
  private
    FTypeName      : string;
    FMethodName     : string;
    FBehaviors      : TList<IBehavior>;
    FReturnDefault  : TValue;
    FExpectations   : TList<IExpectation>;
    FIsStub         : boolean;
    FBehaviorMustBeDefined: boolean;
  protected

    //Behaviors
    procedure WillReturnDefault(const returnValue : TValue);
    procedure WillReturnWhen(const Args: TArray<TValue>; const returnValue : TValue; const matchers : TArray<IMatcher>);
    procedure WillRaiseAlways(const exceptionClass : ExceptClass; const message : string);
    procedure WillRaiseWhen(const exceptionClass : ExceptClass; const message : string;const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
    procedure WillExecute(const func : TExecuteFunc);
    procedure WillExecuteWhen(const func : TExecuteFunc; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);

    function FindBehavior(const behaviorType : TBehaviorType; const Args: TArray<TValue>) : IBehavior; overload;
    function FindBehavior(const behaviorType : TBehaviorType) : IBehavior; overload;
    function FindBestBehavior(const Args: TArray<TValue>) : IBehavior;
    procedure RecordHit(const Args: TArray<TValue>; const returnType : TRttiType; out Result : TValue);



    //Expectations
    function FindExpectation(const expectationType : TExpectationType; const Args: TArray<TValue>) : IExpectation;overload;
    function FindExpectation(const expectationTypes : TExpectationTypes) : IExpectation;overload;

    procedure OnceWhen(const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    procedure Once;
    procedure NeverWhen(const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    procedure Never;
    procedure AtLeastOnceWhen(const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    procedure AtLeastOnce;
    procedure AtLeastWhen(const times : Cardinal; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    procedure AtLeast(const times : Cardinal);
    procedure AtMostWhen(const times : Cardinal; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    procedure AtMost(const times : Cardinal);
    procedure BetweenWhen(const a,b : Cardinal; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    procedure Between(const a,b : Cardinal);
    procedure ExactlyWhen(const times : Cardinal; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    procedure Exactly(const times : Cardinal);
    procedure BeforeWhen(const ABeforeMethodName : string ; const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    procedure Before(const ABeforeMethodName : string);
    procedure AfterWhen(const AAfterMethodName : string;const Args : TArray<TValue>; const matchers : TArray<IMatcher>);
    procedure After(const AAfterMethodName : string);

    function Verify(var report : string) : boolean;
  public
    constructor Create(const ATypeName : string; const AMethodName : string; const AIsStub : boolean; const ABehaviorMustBeDefined: boolean);
    destructor Destroy;override;
  end;

  {$IFNDEF DELPHI_XE_UP}
  ENotImplemented = class(Exception);
  {$ENDIF}

implementation

uses
  Delphi.Mocks.Utils,
  Delphi.Mocks.Behavior,
  Delphi.Mocks.Expectation;



{ TMethodData }


constructor TMethodData.Create(const ATypeName : string; const AMethodName : string; const AIsStub : boolean; const ABehaviorMustBeDefined: boolean);
begin
  FTypeName := ATypeName;
  FMethodName := AMethodName;
  FBehaviors := TList<IBehavior>.Create;
  FExpectations := TList<IExpectation>.Create;
  FReturnDefault := TValue.Empty;
  FBehaviorMustBeDefined := ABehaviorMustBeDefined;
  FIsStub := AIsStub;
end;

destructor TMethodData.Destroy;
begin
  FBehaviors.Free;
  FExpectations.Free;
  inherited;
end;

procedure TMethodData.Exactly(const times: Cardinal);
var
  expectation : IExpectation;
begin
  expectation := FindExpectation([TExpectationType.Exactly,TExpectationType.ExactlyWhen]);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation Exactly for method [%s]', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateExactly(FMethodName,times);
  FExpectations.Add(expectation);
end;

procedure TMethodData.ExactlyWhen(const times: Cardinal; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
var
  expectation : IExpectation;
begin
  expectation := FindExpectation(TExpectationType.ExactlyWhen,Args);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation Exactly for method [%s] with args.', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateExactlyWhen(FMethodName, times, Args, matchers);
  FExpectations.Add(expectation);
end;

function TMethodData.FindBehavior(const behaviorType: TBehaviorType; const Args: TArray<TValue>): IBehavior;
var
  behavior : IBehavior;
begin
  result := nil;
  for behavior in FBehaviors do
  begin
    if behavior.BehaviorType = behaviorType then
    begin
      if behavior.Match(Args) then
      begin
        result := behavior;
        exit;
      end;
    end;
  end;
end;

function TMethodData.FindBehavior(const behaviorType: TBehaviorType): IBehavior;
var
  behavior : IBehavior;
begin
  result := nil;
  for behavior in FBehaviors do
  begin
    if behavior.BehaviorType = behaviorType then
    begin
      result := behavior;
      exit;
    end;
  end;
end;

function TMethodData.FindBestBehavior(const Args: TArray<TValue>): IBehavior;
begin
  //First see if we have an always throws;
  result := FindBehavior(TBehaviorType.WillRaiseAlways);
  if Result <> nil then
    exit;

  //then find an always execute
  result := FindBehavior(TBehaviorType.WillExecute);
  if Result <> nil then
    exit;

  result := FindBehavior(TBehaviorType.WillExecuteWhen,Args);
  if Result <> nil then
    exit;

  result := FindBehavior(TBehaviorType.WillReturn,Args);
  if Result <> nil then
    exit;

  result := FindBehavior(TBehaviorType.ReturnDefault,Args);
  if Result <> nil then
    exit;

  result := nil;

end;


function TMethodData.FindExpectation(const expectationType : TExpectationType; const Args: TArray<TValue>): IExpectation;
var
  expectation : IExpectation;
begin
  result := nil;
  for expectation in FExpectations do
  begin
    if expectation.ExpectationType = expectationType then
    begin
      if expectation.Match(Args) then
      begin
        result := expectation;
        exit;
      end;
    end;
  end;
end;

function TMethodData.FindExpectation(const expectationTypes : TExpectationTypes): IExpectation;
var
  expectation : IExpectation;
begin
  result := nil;
  for expectation in FExpectations do
  begin
    if expectation.ExpectationType in expectationTypes then
    begin
      result := expectation;
      exit;
    end;
  end;
end;

procedure TMethodData.After(const AAfterMethodName: string);
begin
  raise ENotImplemented.Create('After not implented');
end;

procedure TMethodData.AfterWhen(const AAfterMethodName: string; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  raise ENotImplemented.Create('AfterWhen not implented');
end;

procedure TMethodData.AtLeast(const times: Cardinal);
var
  expectation : IExpectation;
begin
  expectation := FindExpectation([TExpectationType.AtLeast,TExpectationType.AtLeastOnce,TExpectationType.AtLeastOnceWhen,TExpectationType.AtLeastWhen]);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation At Least for method [%s]', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateAtLeast(FMethodName,times);
  FExpectations.Add(expectation);
end;

procedure TMethodData.AtLeastOnce;
var
  expectation : IExpectation;
begin
  expectation := FindExpectation([TExpectationType.AtLeast,TExpectationType.AtLeastOnce,TExpectationType.AtLeastOnceWhen,TExpectationType.AtLeastWhen]);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation At Least Once for method [%s]', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateAtLeastOnce(FMethodName);
  FExpectations.Add(expectation);
end;

procedure TMethodData.AtLeastOnceWhen(const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
var
  expectation : IExpectation;
begin
  expectation := FindExpectation(TExpectationType.AtLeastOnceWhen,Args);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation At Least Once When for method [%s]', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateAtLeastOnceWhen(FMethodName, Args, matchers);
  FExpectations.Add(expectation);
end;

procedure TMethodData.AtLeastWhen(const times: Cardinal; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
var
  expectation : IExpectation;
begin
  expectation := FindExpectation(TExpectationType.AtLeastWhen,Args);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation At Least When for method [%s]', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateAtLeastWhen(FMethodName, times, Args, matchers);
  FExpectations.Add(expectation);
end;

procedure TMethodData.AtMost(const times: Cardinal);
var
  expectation : IExpectation;
begin
  expectation := FindExpectation([TExpectationType.AtMost,TExpectationType.AtMostWhen]);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation At Most for method [%s]', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateAtMost(FMethodName, times);
  FExpectations.Add(expectation);
end;

procedure TMethodData.AtMostWhen(const times: Cardinal; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
var
  expectation : IExpectation;
begin
  expectation := FindExpectation(TExpectationType.AtMostWhen,Args);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation At Most When for method [%s]', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateAtMostWhen(FMethodName, times, Args, matchers);
  FExpectations.Add(expectation);
end;

procedure TMethodData.Before(const ABeforeMethodName: string);
begin
  raise ENotImplemented.Create('Before not implented');
end;

procedure TMethodData.BeforeWhen(const ABeforeMethodName: string; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
begin
  raise ENotImplemented.Create('BeforeWhen not implented');
end;

procedure TMethodData.Between(const a, b: Cardinal);
var
  expectation : IExpectation;
begin
  expectation := FindExpectation([TExpectationType.Between,TExpectationType.BetweenWhen]);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation Between for method [%s]', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateBetween(FMethodName,a,b);
  FExpectations.Add(expectation);
end;

procedure TMethodData.BetweenWhen(const a, b: Cardinal;const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
var
  expectation : IExpectation;
begin
  expectation := FindExpectation(TExpectationType.BetweenWhen,Args);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation Between When for method [%s]', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateBetweenWhen(FMethodName, a, b, Args, matchers);
  FExpectations.Add(expectation);
end;

procedure TMethodData.Never;
var
  expectation : IExpectation;
begin
  expectation := FindExpectation([TExpectationType.Never ,TExpectationType.NeverWhen]);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation Never for method [%s]', [FTypeName, FMethodName]));

  expectation := TExpectation.CreateNever(FMethodName);
  FExpectations.Add(expectation);
end;

procedure TMethodData.NeverWhen(const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
var
  expectation : IExpectation;
begin
  expectation := FindExpectation(TExpectationType.NeverWhen,Args);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation Never When for method [%s]', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateNeverWhen(FMethodName, Args, matchers);
  FExpectations.Add(expectation);
end;

procedure TMethodData.Once;
var
  expectation : IExpectation;
begin
  expectation := FindExpectation([TExpectationType.Once,TExpectationType.OnceWhen]);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation Once for method [%s]', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateOnce(FMethodName);
  FExpectations.Add(expectation);
end;

procedure TMethodData.OnceWhen(const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
var
  expectation : IExpectation;
begin
  expectation := FindExpectation(TExpectationType.OnceWhen,Args);
  if expectation <> nil then
    raise EMockException.Create(Format('[%s] already defines Expectation Once When for method [%s]', [FTypeName, FMethodName]));
  expectation := TExpectation.CreateOnceWhen(FMethodName, Args, matchers);
  FExpectations.Add(expectation);
end;


procedure TMethodData.RecordHit(const Args: TArray<TValue>; const returnType : TRttiType; out Result: TValue);
var
  behavior : IBehavior;
  returnVal : TValue;
  expectation : IExpectation;
  expectationHitCtr: integer;
begin
  expectationHitCtr := 0;
  for expectation in FExpectations do
  begin
    if expectation.Match(Args) then
    begin
      expectation.RecordHit;
      inc(expectationHitCtr);
    end;
  end;

  behavior := FindBestBehavior(Args);
  if behavior <> nil then
    returnVal := behavior.Execute(Args,returnType)
  else
  begin
    if (returnType <> nil) and (FReturnDefault.IsEmpty) then
    begin
      if FIsStub then
      begin
        //Stubs return default values.
        result := GetDefaultValue(returnType);
      end
      else
      begin
        //If it's not a stub then we say we didn't have a default return value
        raise EMockException.Create('No default return value defined for method ' + FMethodName);
      end;
    end
    else if FBehaviorMustBeDefined and (expectationHitCtr = 0) and (FReturnDefault.IsEmpty) then
    begin
      //If we must have default behaviour defined, and there was nothing defined raise a mock exception.
      raise EMockException.Create(Format('[%s] has no behaviour or expectation defined for method [%s]', [FTypeName, FMethodName]));
    end;

    returnVal := FReturnDefault;
  end;
  if returnType <> nil then
    Result := returnVal;
end;

function TMethodData.Verify(var report : string) : boolean;
var
  expectation : IExpectation;
begin
  result := true;
  report := '';
  for expectation in FExpectations do
  begin
    if not expectation.ExpectationMet then
    begin
      result := False;
      if report <> '' then
        report := report + #13#10 + '    '
      else
        report :=  '    ';
      report := report +  expectation.Report;
    end;
  end;
  if not result then
    report := '  Method : ' + FMethodName + #13#10 +  report;
end;

//Behaviors

procedure TMethodData.WillExecute(const func: TExecuteFunc);
var
  behavior : IBehavior;
begin
  behavior := FindBehavior(TBehaviorType.WillExecute);
  if behavior <> nil then
    raise EMockSetupException.Create(Format('[%s] already defines WillExecute for method [%s]', [FTypeName, FMethodName]));
  behavior := TBehavior.CreateWillExecute(func);
  FBehaviors.Add(behavior);
end;

procedure TMethodData.WillExecuteWhen(const func: TExecuteFunc;const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
var
  behavior : IBehavior;
begin
  behavior := FindBehavior(TBehaviorType.WillExecuteWhen,Args);
  if behavior <> nil then
    raise EMockSetupException.Create(Format('[%s] already defines WillExecute When for method [%s]', [FTypeName, FMethodName]));
  behavior := TBehavior.CreateWillExecuteWhen(Args, func,matchers);
  FBehaviors.Add(behavior);
end;

procedure TMethodData.WillRaiseAlways(const exceptionClass: ExceptClass; const message : string);
var
  behavior : IBehavior;
begin
  behavior := FindBehavior(TBehaviorType.WillRaiseAlways);
  if behavior <> nil then
    raise EMockSetupException.Create(Format('[%s] already defines Will Raise Always for method [%s]', [FTypeName, FMethodName]));
  behavior := TBehavior.CreateWillRaise(exceptionClass,message);
  FBehaviors.Add(behavior);
end;

procedure TMethodData.WillRaiseWhen(const exceptionClass: ExceptClass; const message : string; const Args: TArray<TValue>; const matchers : TArray<IMatcher>);
var
  behavior : IBehavior;
begin
  behavior := FindBehavior(TBehaviorType.WillRaise,Args);
  if behavior <> nil then
    raise EMockSetupException.Create(Format('[%s] already defines Will Raise When for method [%s]', [FTypeName, FMethodName]));
  behavior := TBehavior.CreateWillRaiseWhen(Args,exceptionClass,message,matchers);
  FBehaviors.Add(behavior);
end;

procedure TMethodData.WillReturnDefault(const returnValue: TValue);
begin
  if not FReturnDefault.IsEmpty then
    raise EMockSetupException.Create(Format('[%s] already defines Will Return Default for method [%s]', [FTypeName, FMethodName]));
  FReturnDefault := returnValue;
end;

procedure TMethodData.WillReturnWhen(const Args: TArray<TValue>; const returnValue: TValue; const matchers : TArray<IMatcher>);
var
  behavior : IBehavior;
begin
  behavior := FindBehavior(TBehaviorType.WillReturn,Args);
  if behavior <> nil then
    raise EMockSetupException.Create(Format('[%s] already defines Will Return When for method [%s]', [FTypeName, FMethodName]));
  behavior := TBehavior.CreateWillReturnWhen(Args,returnValue,matchers);
  FBehaviors.Add(behavior);
end;

end.

