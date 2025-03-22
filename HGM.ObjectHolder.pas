unit HGM.ObjectHolder;

interface

uses
  System.Classes, System.SysUtils;

type
  THolder = class(TComponent)
  private
    FHold: TComponent;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    procedure HoldComponent(AComponent: TComponent);
    function IsLive: Boolean;
  end;

  IComponentHolder = interface
    procedure HoldComponent(AComponent: TComponent);
    function IsLive: Boolean;
  end;

  TComponentHolder = class(TInterfacedObject, IComponentHolder)
  private
    FHolder: THolder;
  public
    procedure HoldComponent(AComponent: TComponent);
    function IsLive: Boolean;
    constructor Create(AComponent: TComponent = nil);
    destructor Destroy; override;
  end;

procedure TaskRun(const Owner: TComponent; Proc: TProc<IComponentHolder>);

procedure Queue(Proc: TThreadProcedure);

procedure Sync(Proc: TThreadProcedure);

procedure ForceQueue(Proc: TThreadProcedure);

implementation

uses
  System.Threading;

procedure TaskRun(const Owner: TComponent; Proc: TProc<IComponentHolder>);
var
  ObjectHold: IComponentHolder;
begin
  ObjectHold := TComponentHolder.Create(Owner);
  TTask.Run(
    procedure
    begin
      try
        Proc(ObjectHold);
      finally
        TThread.ForceQueue(nil,
          procedure
          begin
            ObjectHold := nil;
          end);
      end;
    end);
end;

procedure Queue(Proc: TThreadProcedure);
begin
  TThread.Queue(nil, Proc);
end;

procedure ForceQueue(Proc: TThreadProcedure);
begin
  TThread.ForceQueue(nil, Proc);
end;

procedure Sync(Proc: TThreadProcedure);
begin
  TThread.Synchronize(nil, Proc);
end;

{ THolder }

procedure THolder.HoldComponent(AComponent: TComponent);
begin
  FHold := AComponent;
  AComponent.FreeNotification(Self);
end;

function THolder.IsLive: Boolean;
begin
  Result := Assigned(FHold);
end;

procedure THolder.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
    if AComponent = FHold then
      FHold := nil;
end;

{ TComponentHolder }

constructor TComponentHolder.Create(AComponent: TComponent);
begin
  inherited Create;
  FHolder := THolder.Create(nil);
  FHolder.HoldComponent(AComponent);
end;

destructor TComponentHolder.Destroy;
begin
  FHolder.Free;
  inherited;
end;

procedure TComponentHolder.HoldComponent(AComponent: TComponent);
begin
  FHolder.HoldComponent(AComponent);
end;

function TComponentHolder.IsLive: Boolean;
begin
  Result := FHolder.IsLive;
end;

end.

