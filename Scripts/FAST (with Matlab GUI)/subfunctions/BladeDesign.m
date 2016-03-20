%% Initialization code
function varargout = BladeDesign(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BladeDesign_OpeningFcn, ...
                   'gui_OutputFcn',  @BladeDesign_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

%% Opening function
function BladeDesign_OpeningFcn(hObject, eventdata, handles, varargin)

% Get input
handles.NBlades = varargin{1};
handles.Blade_Cone = varargin{2};
handles.Blade_Radius = varargin{3};
handles.Blade_Twist = varargin{4};
handles.Blade_Chord = varargin{5};
handles.Blade_NFoil = varargin{6};
handles.Blade_Mass = varargin{7};
handles.Blade_EIflap = varargin{8};
handles.Blade_EIedge = varargin{9};
handles.Airfoils = varargin{10};
handles.BladeStyle = varargin{11};
handles.BladePaint = varargin{12};
handles.Input = varargin(1:9);

% Update input fields
set(handles.TableSize_textbox, 'String', length(handles.Blade_Radius));
set(handles.TableSize_slider, 'Value', length(handles.Blade_Radius));
set(handles.NBlades_textbox, 'String', int2str(handles.NBlades));
set(handles.NBlades_slider, 'Value', handles.NBlades);
set(handles.Blade_Cone_textbox, 'String', num2str(handles.Blade_Cone));
NFoil = handles.Blade_NFoil;
AirfoilNames = ...
   {'Cylinder 1', ...
    'Cylinder 2', ...
    'DU 99-W-405', ...
    'DU 99-W-350', ...
    'DU 97-W-300', ...
    'DU 91-W2-250', ...
    'DU 93-W-210', ...
    'NACA 64-618'};
handles.AirfoilNames = AirfoilNames;
Airfoils = cell([length(NFoil),1]);
for i = 1:length(NFoil)
    Airfoils{i} = AirfoilNames{NFoil(i)};
end
set(handles.Table, 'Data', ...
   [num2cell(handles.Blade_Radius), ...
    num2cell(handles.Blade_Chord), ...
    num2cell(handles.Blade_Twist), ...
    Airfoils, ...
    num2cell(handles.Blade_Mass), ...
    num2cell(handles.Blade_EIflap), ...
    num2cell(handles.Blade_EIedge)]);

% Update handles structure
guidata(hObject, handles);

% Halt window
uiwait(handles.BladeDesign);

%% Closing function
function BladeDesign_CloseRequestFcn(hObject, eventdata, handles)
button = questdlg('Save changes?');
if strcmp(button, 'Yes')
    handles.Save = true;
    guidata(hObject, handles);
    uiresume(hObject);
elseif strcmp(button, 'No')
    handles.Save = false;
    guidata(hObject, handles);
    uiresume(hObject);
end

%% Save button
function Apply_Callback(hObject, eventdata, handles)
handles.Save = true;
guidata(hObject, handles);
uiresume(handles.BladeDesign);

%% Cancel button
function Cancel_Callback(hObject, eventdata, handles)
handles.Save = false;
guidata(hObject, handles);
uiresume(handles.BladeDesign);

%% Output function
function varargout = BladeDesign_OutputFcn(hObject, eventdata, handles) 

% Set output
if handles.Save

    % Get geometry from table
    Table = get(handles.Table, 'Data');

    % Find invalid cells
    for i = 1:size(Table,1)
        for j = [1:3, 5:7]
            invalid(i,j) = ...
                isempty(cell2mat(Table(i,j))) + ...
                sum(cell2mat(Table(i,j)) < 0) + ...
                sum(isnan(cell2mat(Table(i,j))));
        end
        invalid(i,4) = isempty(cell2mat(Table(i,4))) + strcmp(Table(i,4), '');
    end

    % Extract geometry from table
    for i = 1:size(Table,1)
        if sum(invalid(i,:)) > 0
            if i <= 2
                Blade_Radius(1:2) = handles.Blade_Radius(1:2);
                Blade_Chord(1:2) = handles.Blade_Chord(1:2);
                Blade_Twist(1:2) = handles.Blade_Twist(1:2);
                Blade_NFoil(1:2) = handles.Blade_NFoil(1:2);
                Blade_Mass(1:2) = handles.Blade_Mass(1:2);
                Blade_EIflap(1:2) = handles.Blade_EIflap(1:2);
                Blade_EIedge(1:2) = handles.Blade_EIedge(1:2);
            end
            break
        else
            Blade_Radius(i) = Table{i,1};
            Blade_Chord(i) = Table{i,2};
            Blade_Twist(i) = Table{i,3};
            Blade_Mass(i) = Table{i,5};
            Blade_EIflap(i) = Table{i,6};
            Blade_EIedge(i) = Table{i,7};
            for j = 1:length(handles.AirfoilNames)
                if strcmp(Table(i,4),handles.AirfoilNames{j})
                    Blade_NFoil(i) = j;
                end
            end
        end
    end
    NBlades = str2double(get(handles.NBlades_textbox, 'String'));
    Blade_Cone = str2double(get(handles.Blade_Cone_textbox, 'String'));
    
    varargout{1} = NBlades;
    varargout{2} = Blade_Cone;
    varargout{3} = Blade_Radius;
    varargout{4} = Blade_Twist;
    varargout{5} = Blade_Chord;
    varargout{6} = Blade_NFoil;
    varargout{7} = Blade_Mass;
    varargout{8} = Blade_EIflap;
    varargout{9} = Blade_EIedge;
    
else
    
    varargout = handles.Input;
    
end

% Close figure
delete(hObject)

%% Number of blades - text box
function NBlades_textbox_Callback(hObject, eventdata, handles)

NBlades = round(str2double(get(hObject, 'String')));
if NBlades < get(handles.NBlades_slider, 'Min')
    NBlades = get(handles.NBlades_slider, 'Min');
elseif NBlades > get(handles.NBlades_slider, 'Max')
    NBlades = get(handles.NBlades_slider, 'Max');
elseif isnan(NBlades)
    NBlades = handles.NBlades;
end    
handles.NBlades = NBlades;
set(hObject, 'String', int2str(NBlades));
set(handles.NBlades_slider, 'Value', NBlades);
guidata(hObject, handles);
function NBlades_textbox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Number of blades - slider
function NBlades_slider_Callback(hObject, eventdata, handles)
NBlades = get(hObject, 'Value');
handles.NBlades = NBlades;
set(handles.NBlades_textbox, 'String', int2str(NBlades));
guidata(hObject, handles);
function NBlades_slider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%% Pre-cone - text box
function Blade_Cone_textbox_Callback(hObject, eventdata, handles)
if isnan(str2double(get(hObject,'String')))
    set(hObject, 'String', num2str(handles.Blade_Cone))
end
handles.Blade_Cone = str2double(get(hObject,'String'));
guidata(hObject, handles);
function Blade_Cone_textbox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Table size - text box
function TableSize_textbox_Callback(hObject, eventdata, handles)

rows = ceil(str2double(get(hObject, 'String')));
Table = get(handles.Table, 'Data');
if rows < 2
    rows = 2;
elseif rows > get(handles.TableSize_slider, 'Max')
    rows = get(handles.TableSize_slider, 'Max');
elseif isnan(rows)
    rows = size(Table,1);
end
if rows < size(Table,1)
    Table = Table(1:rows,:);
    set(handles.Table, 'Data', Table);
elseif rows > size(Table,1)
    Table{rows,size(Table,2)} = [];
    set(handles.Table, 'Data', Table);
end
set(hObject, 'String', int2str(rows));
set(handles.TableSize_slider, 'Value', rows);
function TableSize_textbox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Table size - slider
function TableSize_slider_Callback(hObject, eventdata, handles)
rows = get(hObject, 'Value');
Table = get(handles.Table, 'Data');
if rows < 2
    set(hObject, 'Value', 2);
else
    if rows < size(Table,1)
        Table = Table(1:rows,:);
        set(handles.Table, 'Data', Table);
    elseif rows > size(Table,1)
        Table{rows,size(Table,2)} = [];
        set(handles.Table, 'Data', Table);
    end
    set(handles.TableSize_textbox, 'String', int2str(rows));
end
function TableSize_slider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%% Edit cells - checkbox
function EditCells_checkbox_Callback(hObject, eventdata, handles)
if get(hObject, 'Value') == 1
    set(handles.Table, 'ColumnEditable', [true true true true true true true]);
else
    set(handles.Table, 'ColumnEditable', [false false false false false false false]);
end

%% Plot geometry
function PlotButton_Callback(hObject, eventdata, handles)

% Extract geometry from table
Table = get(handles.Table, 'Data');
for i = 1:size(Table,1)
    if isempty(Table{i,1})
        Blade_Radius(i) = NaN;
    else
        Blade_Radius(i) = Table{i,1};
    end
    if isempty(Table{i,2})
        Blade_Chord(i) = NaN;
    else
        Blade_Chord(i) = Table{i,2};
    end
    if isempty(Table{i,3})
        Blade_Twist(i) = NaN;
    else
        Blade_Twist(i) = Table{i,3};
    end
    for j = 1:length(handles.AirfoilNames)
        if strcmp(Table(i,4),handles.AirfoilNames{j})
            Blade_NFoil(i) = j;
        end
    end
end

% Smooth pitch axis
Blade_NFoil(Blade_NFoil < 1) = 1;
Blade_PitchAxis = NaN(size(Blade_Radius));
Blade_PitchAxis(Blade_NFoil == 1) = 0.5;
Blade_PitchAxis(Blade_NFoil >= 4) = 0.375;
Blade_PitchAxis(isnan(Blade_PitchAxis)) = interp1(...
    Blade_Radius(~isnan(Blade_PitchAxis)), ...
    Blade_PitchAxis(~isnan(Blade_PitchAxis)), ...
    Blade_Radius(isnan(Blade_PitchAxis)));

% Color scheme
EdgeColor = 'none';
White = [240, 240, 240]/255;
Grey = [120, 120, 120]/255;

% Set axis
Plot = figure();
set(Plot, 'Name', 'Blade plot')
view(-45,180/pi*atan(sin(pi/4)))
light
lightangle(0, 45)
axis equal
axis off
hold on

% Plot blade
x = [];
y = [];
for i = 1:length(Blade_NFoil)
    x = [x; ([handles.Airfoils{Blade_NFoil(i)}(1,:), handles.Airfoils{Blade_NFoil(i)}(1,1)] - Blade_PitchAxis(i)) * Blade_Chord(i)];
end
for i = 1:length(Blade_NFoil)
    t_u = max(handles.Airfoils{Blade_NFoil(i)}(2,1:200) * Blade_Chord(i));
    t_l = min(handles.Airfoils{Blade_NFoil(i)}(2,200:end) * Blade_Chord(i));
    t(i) = t_u - t_l;
end
s = 2.*round((length(Blade_NFoil)/5+1)/2)-1;
t = conv(t(:),s(:)/sum(s),'same')./t(:);
for i = 1:length(Blade_NFoil)
    y = [y; -1*[handles.Airfoils{Blade_NFoil(i)}(2,:), handles.Airfoils{Blade_NFoil(i)}(2,1)] * Blade_Chord(i)*t(i)];
end
z = repmat(Blade_Radius(:),[1,size(x,2)]);
for i = 1:length(Blade_NFoil)
    t = pi/2 - Blade_Twist(i) * pi/180;
    Rz = [cos(t),-sin(t), 0; ...
          sin(t), cos(t), 0; ...
          0,      0,      1];
    A = Rz * [x(i,:); y(i,:); z(i,:)];
    x(i,:) = A(1,:);
    y(i,:) = A(2,:);
    z(i,:) = A(3,:);
end
x = [x(1,:); x; 0.5*x(end,:)];
y = [y(1,:); y; 0*y(end,:)];
z = [0*z(1,:); z; 0.01 + z(end,:)];
Rx = [1, 0,       0; ...
      0, cos(pi),-sin(pi); ...
      0, sin(pi), cos(pi)];
Ry = [cos(pi/2), 0, sin(pi/2); ...
      0,         1, 0; ...
     -sin(pi/2), 0, cos(pi/2)];
A = Rx * Ry * [reshape(x,1,[]); reshape(y,1,[]); reshape(z,1,[])];
N = size(x);

s = Blade_Radius/Blade_Radius(end);
if handles.BladeStyle == 1
    paint = zeros(size(s));
elseif handles.BladeStyle == 2
    paint = ones(size(s));
elseif handles.BladeStyle == 3
    paint = zeros(size(s));
    paint(s > 0.25) = 1;
    paint(s > 0.50) = 0;
    paint(s > 0.75) = 1;
elseif handles.BladeStyle == 4
    paint = zeros(size(s));
    paint(s > 0.125) = 1;
    paint(s > 0.250) = 0;
    paint(s > 0.375) = 1;
    paint(s > 0.500) = 0;
    paint(s > 0.625) = 1;
    paint(s > 0.750) = 0;
    paint(s > 0.875) = 1;
elseif handles.BladeStyle == 5
    paint = (s > 0.8);
elseif handles.BladeStyle == 6
    paint = zeros(size(s));
    paint(s > 0.650) = 1;
    paint(s > 0.750) = 0;
    paint(s > 0.875) = 1;
elseif handles.BladeStyle == 7
    paint = zeros(size(s));
    paint(s > 0.70) = 1;
    paint(s > 0.75) = 0;
    paint(s > 0.80) = 1;
elseif handles.BladeStyle == 8
    paint = zeros(2,size(s,2));
    paint(1,s > 0.80) = 0;
    paint(1,s > 0.85) = 1;
    paint(1,s > 0.90) = 0;
    paint(1,s > 0.95) = 1;
    paint(2,s > 0.80) = 1;
    paint(2,s > 0.85) = 0;
    paint(2,s > 0.90) = 1;
    paint(2,s > 0.95) = 0;
    paint = [paint; paint];
elseif handles.BladeStyle == 9
    paint = (s < 0.15);
end
if handles.BladeStyle == 8
    paint = kron(paint,ones(round((N(2)+1)/4),1));
    paint = paint(1:N(2),:);
    BladeColors = zeros([size(paint),3]);
    BladeColors(:,:,1) = paint*handles.BladePaint(1) + (1-paint)*White(1);
    BladeColors(:,:,2) = paint*handles.BladePaint(2) + (1-paint)*White(2);
    BladeColors(:,:,3) = paint*handles.BladePaint(3) + (1-paint)*White(3);
    BladeColors = permute(BladeColors,[2,1,3]);
else
    BladeColors = kron(paint(:),handles.BladePaint) + kron((1-paint(:)),White);
    BladeColors = repmat(BladeColors,[1,1,N(2)]);
    BladeColors = permute(BladeColors,[1,3,2]);
end

x = reshape(A(1,:),N);
y = reshape(A(2,:),N);
z = reshape(A(3,:),N);
surf(x,y,z, ...
    'CData', BladeColors, ...
    'FaceColor', 'texturemap', ...
    'EdgeColor', EdgeColor, ...
    'AmbientStrength', 0.5, ...
    'DiffuseStrength', 0.5, ...
    'SpecularStrength', 0.5, ...
    'BackFaceLighting', 'reverselit')

xlim([min(x(:)) - 0.3, max(x(:))])
ylim([min(y(:)), max(y(:))])
zlim([min(z(:)), max(z(:))])

x_ = x;
y_ = 0.8*y .* (max(x(:)) - x)/max(x(:));
z_ = 0.8*z .* (max(x(:)) - x)/max(x(:));

surf(x_,y_,z_, ...
    'FaceColor', Grey, ...
    'EdgeColor', EdgeColor, ...
    'AmbientStrength', 0.5, ...
    'DiffuseStrength', 0.5, ...
    'SpecularStrength', 0.5, ...
    'BackFaceLighting', 'reverselit')

patch(...
    [x(1,:), flip(x_(1,:))], ...
    [y(1,:), flip(y_(1,:))], ...
    [z(1,:), flip(z_(1,:))], ...
    'g', 'FaceColor', White, ...
    'EdgeColor', EdgeColor, ...
    'AmbientStrength', 0.5, ...
    'DiffuseStrength', 0.5, ...
    'SpecularStrength', 0.5, ...
    'BackFaceLighting', 'reverselit')

if Blade_NFoil(1) == 1
    R = 0.9/2*Blade_Chord(1);
    r = 0.05/2*Blade_Chord(1);
    [x_,y_,z_] = cylinder([r r],12);
    for t = pi/15:pi/15:2*pi
        x = 0.3*z_ - 0.1;
        y = x_ + R*cos(t);
        z = y_ + R*sin(t);
        surf(x,y,z, ...
            'FaceColor', Grey, ...
            'EdgeColor', EdgeColor, ...
            'AmbientStrength', 0.5, ...
            'DiffuseStrength', 0.5, ...
            'SpecularStrength', 0.5, ...
            'BackFaceLighting', 'reverselit')
        patch(x(1,:), y(1,:), z(1,:), ...
            'g', 'FaceColor', Grey, ...
            'EdgeColor', EdgeColor, ...
            'AmbientStrength', 0.5, ...
            'DiffuseStrength', 0.5, ...
            'SpecularStrength', 0.5, ...
            'BackFaceLighting', 'reverselit')
    end
end

xlabel('r [m]')
ylabel('x [m]')
zlabel('z [m]')
lighting gouraud

%% Table cell selection
function Table_CellSelectionCallback(hObject, eventdata, handles)
handles.Selection = eventdata.Indices;
guidata(hObject, handles); 

%% Table keyboard functions
function Table_KeyPressFcn(hObject, eventdata, handles)

% Paste functionality
if strcmpi(char(eventdata.Modifier),'control') && strcmp(eventdata.Key, 'v')
    
    % Get and reshape clipboard data
    Paste = clipboard('paste');
    rows = numel(strsplit(strtrim(Paste), '\n'));
    Paste = strsplit(strtrim(Paste));
    columns = numel(Paste)/rows;
    Paste = reshape(Paste,columns,rows)';
    
    % Find airfoil column
    merge = false;
    for j = 1:columns
        if sum(strcmpi(Paste{1,j}, {'Cylinder', 'DU', 'NACA'})) > 0
            merge = true;
            break;
        end
    end
    if merge
        for i = 1:rows
            Paste{i,j} = [Paste{i,j}, ' ', Paste{i,j+1}];
        end
        if j+2 <= columns
            Paste(:,j+1:end-1) = Paste(:,j+2:end);
        end
        Paste = Paste(:,1:end-1);
        columns = columns - 1;
    else
        j = 1e6;
    end
    
    % Convert numeric cells
    for i = 1:rows
        for k = 1:columns
            if k ~= j
                Paste{i,k} = str2double(Paste{i,k});
            end
        end
    end

    % Target cells
    Table = get(hObject, 'Data');
    Selection = handles.Selection;
    i1 = Selection(1,1);
    i2 = Selection(1,1) + (rows-1);
    j1 = Selection(1,2);
    j2 = Selection(1,2) + (columns-1);
    if i2 > size(Table,1)
        if i2 > get(handles.TableSize_slider, 'Max')
            i2 = get(handles.TableSize_slider, 'Max');
        end
        set(handles.TableSize_textbox, 'String', int2str(i2));
        set(handles.TableSize_slider, 'Value', i2);
    end
    if j2 > size(Table,2)
        j2 = size(Table,2);
    end
    
    % Constrain data types
    Table(i1:i2,j1:j2) = Paste(1:(1+i2-i1),1:(1+j2-j1));
    for i = i1:i2
        for j = [1:3,5:7]
            if ~isnumeric(Table{i,j})
                Table{i,j} = NaN;
            end
        end
        if isnumeric(Table{i,4})
            Table{i,4} = ' ';
        end
    end

    % Update table
    set(hObject, 'Data', Table);

end
