function varargout = fCreateProject(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @fCreateProject_OpeningFcn, ...
                   'gui_OutputFcn',  @fCreateProject_OutputFcn, ...
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


function fCreateProject_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = struct;
if length(varargin) > 1
    if ~ischar(varargin{2}), error('First input argument must be a valid path'); end
    if ~exist(varargin{2}, 'dir'), error('First input argument must be a valid path'); end
    handles.output.sPath = varargin{2};
else
    handles.output.sPath = cd;
end
handles.output.sProject = '';
handles.output.sStudyPath = '';
handles.output.csPatients = {};
handles.output.STestCases = struct;
handles.output.lOptions   = false(3, 1);
handles.output.lOK        = false;
guidata(hObject, handles);

movegui(hObject, 'center');
uiwait(handles.figure1);


function varargout = fCreateProject_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;
delete(handles.figure1);


function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if strcmp(get(hObject, 'waitstatus'), 'waiting')
    uiresume(hObject);
else
    delete(hObject);
end




function FileButton_Callback(hObject, eventdata, handles)
[sFilename, sPath] = uiputfile('*.mat', 'Choose Projectname', handles.output.sPath);
if isnumeric(sPath), return, end;   % Dialog aborted

handles.output.sPath = sPath;
handles.output.sProject = [sPath, sFilename];
set(get(hObject, 'Parent'), 'Name', sprintf('New Blindfold Project [%s]', sFilename));

if isempty(handles.output.sStudyPath)
    handles.output.sStudyPath = sPath;
end
guidata(hObject, handles);
fUpdatePatients(handles);


function PathButton_Callback(hObject, eventdata, handles)
sStudyPath = uigetdir(handles.output.sPath);
if isnumeric(sStudyPath), return, end;

handles.output.sStudyPath = sStudyPath;
guidata(hObject, handles);
fUpdatePatients(handles);


function listbox1_Callback(hObject, eventdata, handles)
iInd = get(hObject, 'Value');
if isempty(iInd)
    set(handles.listbox2, 'String', [], 'Value', []);
else
    csDirs = get(hObject, 'String');
    sTestDir = csDirs{min(iInd)};
    SDir = dir([handles.output.sStudyPath, filesep, sTestDir]);
    SDir = SDir(3:end);
    set(handles.listbox2, 'Value', [], 'String', {SDir.name});
end
csPatients = get(hObject, 'String');
handles.output.csPatients = csPatients(get(hObject, 'Value'));
guidata(hObject, handles);


function listbox2_Callback(hObject, eventdata, handles)
% -------------------------------------------------------------------------
% Unselect all data
set(handles.listbox3, 'Value', []);


function listbox3_Callback(hObject, eventdata, handles)
% -------------------------------------------------------------------------
% Testcase selected: Show information
iInd = get(hObject, 'Value');
if ~isempty(iInd), iInd = iInd(1); end
set(hObject, 'Value', iInd);
fShowTestcase(handles, iInd);


function AddButton_Callback(hObject, eventdata, handles)
iInd = get(handles.listbox2, 'Value');
if isempty(iInd), return, end

iDataInd = length(handles.output.STestCases);
iDataInd = iDataInd + 1;
if ~isfield(handles.output.STestCases, 'csData'), iDataInd = 1; end

csDatasets = get(handles.listbox2, 'String');
handles.output.STestCases(iDataInd).csData = csDatasets(iInd);
handles.output.STestCases(iDataInd).iReference = 0;
handles.output.STestCases(iDataInd).sPrompt = '';
handles.output.STestCases(iDataInd).iNRatings = 5;
handles.output.STestCases(iDataInd).ImageType = 0;
guidata(hObject, handles);
fFillTestcases(handles, iDataInd);
fShowTestcase(handles, iDataInd);

% --- Executes on button press in DelButton.
function DelButton_Callback(hObject, eventdata, handles)
iInd = get(handles.listbox3, 'Value');
if isempty(iInd), return, end

handles.output.STestCases(iInd) = [];
guidata(hObject, handles);
if iInd > length(handles.output.STestCases)
    if iInd == 1, iInd = []; else iInd = iInd - 1; end
end
fFillTestcases(handles, iInd);
fShowTestcase(handles, iInd);

% --- Executes on selection change in RefCombo.
function RefCombo_Callback(hObject, eventdata, handles)
iInd = get(hObject, 'Value');
iDataInd = get(handles.listbox3, 'Value');
if(~isempty(iDataInd))
    handles.output.STestCases(iDataInd).iReference = iInd - 1;
end
guidata(hObject, handles);


function OKButton_Callback(hObject, eventdata, handles)
if isempty(handles.output.sProject), errordlg('No project file selected!'); return, end
if isempty(handles.output.csPatients), errordlg('No patients selected!'); return, end
if ~isfield(handles.output.STestCases, 'csData'), errordlg('No testcases defined'); return, end

sFirstPatient = handles.output.csPatients{1};
STestcases = handles.output.STestCases;
iNonEmpty = find(arrayfun(@(s) ~isempty(s.sPrompt), STestcases),1,'first'); % find non-empty testcases
hW = waitbar(0, 'Verifying testcases');
for iI = 1:length(STestcases)
    % update sPrompt, ratings and image type (must be the same for all
    % testcases
    handles.output.STestCases(iI).sPrompt = handles.output.STestCases(iNonEmpty).sPrompt;
    handles.output.STestCases(iI).iNRatings = handles.output.STestCases(iNonEmpty).iNRatings;
    handles.output.STestCases(iI).ImageType = handles.output.STestCases(iNonEmpty).ImageType;
    csData = STestcases(iI).csData;
    if(strcmp(handles.output.sStudyPath(end),filesep)), handles.output.sStudyPath = handles.output.sStudyPath(1:end-1); end
    dFirstSize = fGetSize([handles.output.sStudyPath, filesep, sFirstPatient, filesep, csData{1}]);
    if ischar(dFirstSize)
        errordlg(dFirstSize);
        delete(hW);
        break
    end
    if length(csData) > 1
        for iJ = 2:length(csData)
            dSize = fGetSize([handles.output.sStudyPath,  filesep, sFirstPatient, filesep, csData{iJ}]);
            if ischar(dSize)
                errordlg(dSize);
                delete(hW);
                return
            end
            if(length(dSize) == 4) % sneaky workaround for 4D compare with different #gates
                if(any(dSize(1:3) ~= dFirstSize(1:3)))
                    errordlg('Error in testcase %d%: Data mismatch', iI);
                    delete(hW);
                    return
                end
            else
                if any(dSize ~= dFirstSize)
                    errordlg('Error in testcase %d%: Data mismatch', iI);
                    delete(hW);
                    return
                end
            end
        end
    end
    waitbar(iI./length(STestcases), hW);
end
delete(hW);
handles.output.iNRatings = str2double(get(handles.RatingEdit, 'String'));
handles.output.lOK = true;

% Create the permutations
handles.output.iPatientPermutation = randperm(length(handles.output.csPatients));
guidata(hObject, handles);
uiresume;


function CancelButton_Callback(hObject, eventdata, handles)
uiresume;


function RatingEdit_Callback(hObject, eventdata, handles)
iDataInd = get(handles.listbox3, 'Value');
handles.output.STestCases(iDataInd).iNRatings = str2double(get(hObject, 'String'));
guidata(hObject, handles);


function PromptEdit_Callback(hObject, eventdata, handles)
iDataInd = get(handles.listbox3, 'Value');
handles.output.STestCases(iDataInd).sPrompt = get(hObject, 'String');
guidata(hObject, handles);


function fFillTestcases(handles, iInd)
if isempty(handles.output.STestCases)
    set(handles.listbox3, 'String', []);
    set([handles.RefCombo, handles.ModeCombo], 'Value', 1);
else
    csTestCases = cell(length(handles.output.STestCases), 1);
    for iI = 1:length(csTestCases)
        csTestCases{iI} = sprintf('[%d]: N = %d', iI, length(handles.output.STestCases(iI).csData));
    end
    set(handles.listbox3, 'String', csTestCases, 'Value', iInd);
end

function fUpdatePatients(handles)
SDir = dir(handles.output.sStudyPath);
SDir = SDir([SDir.isdir]);
SDir = SDir(3:end);
set(handles.listbox1, 'String', {SDir.name});
set(handles.listbox1, 'Value', 1:length(SDir));
handles.output.csPatients = {SDir.name};
guidata(handles.figure1, handles);

listbox1_Callback(handles.listbox1, [], handles);

function fShowTestcase(handles, iInd)
if iInd <= length(handles.output.STestCases)
    STestcase = handles.output.STestCases(iInd);
    if isfield(STestcase, 'csData')
        csDatasets = get(handles.listbox2, 'String');
        lValue = false(size(csDatasets));
        for iI = 1:length(STestcase.csData)
            lValue = lValue | strcmp(csDatasets, STestcase.csData{iI});
        end
        set(handles.listbox2, 'Value', find(lValue));
        set(handles.RefCombo, 'String', ['[none]'; STestcase.csData]);
        set(handles.RefCombo, 'Value', STestcase.iReference + 1);
        set(handles.PromptEdit, 'String', STestcase.sPrompt);
        set(handles.RatingEdit, 'String', num2str(STestcase.iNRatings));
    else
        set(handles.RefCombo, 'String', '[none]');
        set(handles.RefCombo, 'Value', 1);
        set(handles.listbox2, 'Value', []);
        set(handles.PromptEdit, 'String', '');
        set(handles.RatingEdit, 'String', '5');
    end
else
    set(handles.RefCombo, 'String', '[none]');
    set(handles.RefCombo, 'Value', 1);
    set(handles.listbox2, 'Value', []);
    set(handles.PromptEdit, 'String', '');
    set(handles.RatingEdit, 'String', '5');
end

function xAns = fGetFolder(sPath)
xAns = [];
SDir = dir(sPath);
SDir = SDir(~[SDir.isdir]);
if isempty(SDir)
    xAns = sprintf('No files in folder ''%s''!', sPath);
    return
end

csExt = cell(size(SDir));
for iI = 1:length(SDir)
    [temp, sFile, sExt] = fileparts(SDir(iI).name);
    csExt{iI} = sExt;
end
csExtensions = unique(csExt);
iHist = zeros(length(csExtensions));
for iI = 1:length(iHist)
    iHist(iI) = nnz(strcmp(csExt, csExtensions{iI}));
end
[iMax, iInd] = max(iHist);
sExt = csExtensions{iInd};
fprintf(1, 'Primary extension in ''%s'' is ''%s''.\n', sPath, sExt);
SDir = SDir(strcmp(csExt, sExt));
if any(strcmp({'.jpg', '.jpeg', '.tif', '.tiff', '.gif', '.bmp', '.png'}, sExt))
    dFirstImg = imread([sPath, SDir(1).name]);
    iFirstSize = size(dFirstImg);
    xAns = zeros([iFirstSize, length(SDir)]);
    xAns(:,:,1) = dFirstImg;
    if length(SDir) > 1
        for iI = 2:length(SDir)
            dThisImg = imread([sPath, SDir(iI).name]);
            if any(size(dThisImg) ~= iFirstSize)
                xAns = sprintf('Folder ''%s'' contains unmatching data!', sPath);
                return
            end
            xAns(:,:,iI) = dThisImg;
        end
    end
else
    iInd = 1;
    xAns = [];
    try
        for iI = 1:length(SDir)
            dThisImg = [];
            dThisImg = dicomread([sPath, filesep, SDir(iI).name]); 
            [~,msgID] = lastwarn();
            if(strcmp(msgID,'images:dicomparse:shortImport')), error('Matlab DICOM read'); end    
            if ~isempty(dThisImg)
                if isempty(xAns)
                    xAns = dThisImg;
                else
                    if size(xAns, 1) ~= size(dThisImg, 1) || size(xAns, 2) ~= size(dThisImg, 2)
                        xAns = sprintf('Folder ''%s'' contains unmatching data!', sPath);
                        return
                    end
                    xAns(:,:,iInd) = dThisImg;
                    iInd = iInd + 1;
                end
            end
        end
    catch
        xAns = fReadDICOM(sPath);    
    end
end
if isempty(xAns)
    error('No data found in folder ''%s''!', sPath);
end

function xAns = fGetSize(sPath)

xAns = [];
if exist(sPath, 'dir') % A directory: Either images or DICOMs
    dImg = fGetFolder(sPath);
    if ischar(dImg)
        xAns = dImg;
    else
        xAns = size(dImg);
    end
else % A File: Images, DICOMS, mat, GIPL, NifTy
    [sPath, sFile, sExt] = fileparts(sPath);
    switch(lower(sExt))
        case '.mat'
            SInfo = whos('-file', [sPath, filesep, sFile, sExt]);
            if (length(SInfo) ~= 1)
                xAns = sprintf('Mat files may only contain a single variable!');
                return
            end
            xAns = SInfo.size;
            
        case '.gipl'
            fid = fopen(sPath, 'rb', 'ieee-be');
            if fid < 0
                xAns = sprintf('Could not open the file ''%s''!', sPath);
                return
            end
            xAns = fread(fid,  4, 'ushort')';
            fclose(fid);
            
        case '.nii'
            fid = fopen(sPath, 'rb');
            if(fid < 0)
                xAns = sprintf('Could not open the file ''%s''!', sPath);
                return
            end
            fseek(fid, 42, 'bof');
            xAns = fread(fid, 7, 'uint16');
            fclose(fid);
            
        case {'.jpg', '.jpeg', '.tif', '.tiff', '.gif', '.bmp', '.png'}
            dImg = imread(sPath);
            xAns = size(dImg);
            
        otherwise
    end
end

function fCreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu11.
function popupmenu11_Callback(hObject, eventdata, handles)
iInd = get(hObject, 'Value');
iDataInd = get(handles.listbox3, 'Value');
if(~isempty(iDataInd))
    handles.output.STestCases(iDataInd).ImageType = iInd - 1;
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function popupmenu11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
