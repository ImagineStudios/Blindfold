function hF = blindfold(sProject)
% BLINDFOLD User interface for blind reading and comparison of datasets
%
% Copyright 2014-2015 Christian Wuerslin, University of Tuebingen, Stanford
% University
% Contact: wuerslin@stanford.edu
% Modifications 2015 Thomas Kuestner, University of Tuebingen, University of 
% Stuttgart, thomas.kuestner@iss.uni-stuttgart.de

% =========================================================================
% Warp Zone! (using Cntl + D)
% -------------------------------------------------------------------------
% *** The callbacks ***
% fCloseGUI                 % On figure close
% fResizeFigure             % On figure resize
% fIconClick                % On clicking menubar icons
% fWindowMouseHoverFcn      % Standard figure mouse move callback
% fWindowButtonDownFcn      % Figure mouse button down function
% fWindowMouseMoveFcn       % Figure mouse move function when button is pressed or ROI drawing active
% fWindowButtonUpFcn        % Figure mouse button up function: Starts most actions
% fKeyPressFcn              % Keyboard callback
% fChangeImage
%
% fFillPanels
% fCreatePanels
% fCreateRating
% fRate
% fUpdateRatings
% fUpdateActivation
% fUpdateProgress
% fLoadData
% fOpenFolder
% fGetPermutation
% fGetPanel
% fIsOn
% fBackgroundImg
% fReplicate
% fBlend
% =========================================================================

% =========================================================================
% *** FUNCTION blindfold
% ***
% *** Main GUI function. Creates the figure and all its contents and
% *** registers the callbacks.
% ***
% =========================================================================
warning('off','MATLAB:HandleGraphics:UicontrolUnitsAfterPosition');
% -------------------------------------------------------------------------
% Control the figure's appearance
SAp.sVERSION          = '1.1';
SAp.sTITLE            = ['BlindFold ',SAp.sVERSION];% Title of the figure
SAp.iICONSIZE         = 24;                     % Size if the icons
SAp.iICONPADDING      = SAp.iICONSIZE/2;        % Padding between icons
SAp.iMENUBARHEIGHT    = SAp.iICONSIZE.*2;       % Height of the menubar (top)
SAp.iTITLEBARHEIGHT   = 24;                     % Height of the titles (above each image)
SAp.iSTATUSBARHEIGHT  = 24;
SAp.iDISABLED_SCALE   = 0.1;                    % Brightness of disabled buttons (decrease to make darker)
SAp.iINACTIVE_SCALE   = 0.3;                    % Brightness of inactive buttons (toggle buttons and radio groups)
SAp.iACTIVE_SCALE     = 0.8;
SAp.dBGCOLOR          = [0.6 0.7 0.8];          % Color scheme
SAp.dGRIDCOLOR        = [0.4 0.4 0.4];
SAp.dPANELCOLOR       = SAp.dBGCOLOR;
SAp.dEmptyImg         = 0;                      % The background image (is calculated in fResizeFigure);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Define some preferences
SPref.dWINDOWSENSITIVITY    = 0.02;     % Defines mouse sensitivity for windowing operation
SPref.dZOOMSENSITIVITY      = 0.02;     % Defines mouse sensitivity for zooming operation
SPref.dROTATION_THRESHOLD   = 50;       % Defines the number of pixels the cursor has to move to rotate an image
SPref.lGERMANEXPORT         = false;    % Not a beer! Determines whether the data is exported with a period or a comma as decimal point
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Set some paths.
SPref.sMFILEPATH    = fileparts(mfilename('fullpath'));                 % This is the path of this m-file
SPref.sICONPATH     = [SPref.sMFILEPATH, filesep, 'icons', filesep];    % That's where the icons are
SPref.sSaveFilename = [SPref.sMFILEPATH, filesep, 'blindfoldSave.mat'];   % A .mat-file to save the GUI settings
addpath([SPref.sMFILEPATH, filesep, 'import']);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% This is the definition of the menubar. If a radiobutton-like
% functionality is to implemented, the GroupIndex parameter of all
% icons within the group has to be set to the same positive integer
% value. Normal Buttons have group index -1, toggel switches have group
% index 0.
SIcons = struct( ...
    'Name',        {    'doc_new',  'folder_open',               'info',         'bars',          'id', 'first',   'rewind',          'play',         'stop',      'next', 'last',           'auto',     'cursor_arrow', 'rotate', '4d'}, ...
    'Spacer',      {            0,              0,                    0,              1,             1,       0,          0,               0,              0,           0,      1,                1,                  0,        1,    0}, ...
    'GroupIndex',  {           -1,             -1,                   -1,             -1,            -1,      -1,         -1,              -1,             -1,          -1,     -1,                0,                255,      255,  -10}, ...
    'Enabled',     {            1,              1,                    0,              1,             1,       0,          0,               0,              0,           0,      0,                1,                  1,        1,    0}, ...
    'Active',      {            1,              1,                    1,              1,             1,       1,          1,               1,              1,           1,      1,                1,                  1,        0,    0}, ...
    'Accelerator', {          'n',            'o',                  'p',             '',           'u',      '',   'return',             's',            't'     'return',     '',              'i',                'm',      'r',   ''}, ...
    'Modifier',    {       'Cntl',         'Cntl',               'Cntl',             '',        'Cntl',      '',     'Cntl',          'Cntl',         'Cntl',          '',     '',           'Cntl',                 '',       '',   ''}, ...
    'Tooltip',     {'New Project', 'Open Project', 'Project Properties', 'Show Results', 'Change User', 'First', 'Previous', 'Start Reading', 'Stop Reading',      'Next', 'Last', 'Auto Increment', 'Move/Zoom/Window', 'Rotate','Change Gate [4|5]'});
% -------------------------------------------------------------------------

% ------------------------------------------------------------------------
% Reset the GUI's state variable
SState.sPath            = [SPref.sMFILEPATH, filesep];
SState.iPanels          = [1, 1];
SState.sUser            = '';
SState.lReading         = false;

SState.iTestcase        = 1;
SState.iPatient         = 1;

SState.cRating          = {};
SState.iLastHover       = [0, 0];
SState.iPermutation     = [];
SState.sTool            = 'cursor_arrow';
% ------------------------------------------------------------------------

% ------------------------------------------------------------------------
% Create some globals
SProject                = [];
SData                   = [];    % A struct for hoding the data (image data + visualization parameters)
SImg                    = [];    % A struct for the image component handles
SMouse                  = [];    % A Struct to hold parameters of the mouse operations
SPanels                 = [];    % A Struct to hold the panel data
% csUsers                 = {getenv('username')};
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Read the preferences from the save file
iPosition = [100 100 1000 600];
if exist(SPref.sSaveFilename, 'file')
    load(SPref.sSaveFilename);
    SState.sPath            = SSaveVar.sPath;
    iPosition               = SSaveVar.iPosition;
    SPref.lGERMANEXPORT     = SSaveVar.lGermanExport;
    clear SSaveVar; % <- no one needs you anymore! :((
else
    sAns = questdlg('Do you want to use periods (anglo-american) or commas (german) as decimal separator in the exported .csv spreadsheet files? This is important for a smooth Excel import.', 'BLINDFOLD First-Time Setup', 'Stick to the point', 'Use se commas', 'Stick to the point');
    SPref.lGERMANEXPORT = strcmp(sAns, 'Use se commas');
end
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Make sure the figure fits on the screen
iScreenSize = get(0, 'ScreenSize');
if (iPosition(1) + iPosition(3) > iScreenSize(3)) || ...
        (iPosition(2) + iPosition(4) > iScreenSize(4))
    iPosition(1:2) = 50;
    iPosition(3:4) = iScreenSize(3:4) - 100;
end
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Create the figure. Mouse scroll wheel is supported since Version 7.4 (I think).
hF = figure(...
    'BusyAction'           , 'cancel', ...
    'Interruptible'        , 'off', ...
    'Position'             , iPosition, ...
    'Units'                , 'pixels', ...
    'Color'                , SAp.dGRIDCOLOR, ...
    'ResizeFcn'            , @fResizeFigure, ...
    'DockControls'         , 'on', ...
    'MenuBar'              , 'none', ...
    'Name'                 , SAp.sTITLE, ...
    'NumberTitle'          , 'off', ...
    'KeyPressFcn'          , @fKeyPressFcn, ...
    'CloseRequestFcn'      , @fCloseGUI, ...
    'WindowButtonDownFcn'  , @fWindowButtonDownFcn, ...
    'WindowButtonMotionFcn', @fWindowMouseHoverFcn);
try
    set(hF, 'WindowScrollWheelFcn' , @fChangeImage);
end
colormap(gray(256));

try % Try to apply a nice icon
    warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    jframe = get(hF, 'javaframe');
    mw = 142.3;
    jIcon = javax.swing.ImageIcon([SPref.sICONPATH, 'Icon.png']);
    pause(0.001);
    jframe.setFigureIcon(jIcon);
    clear jframe jIcon
catch
    %     warning('IMAGINE: Could not apply a nifty icon to the figure :(');
end
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Create the menubar and the toolbar including their components
SPanels.hMenu  = uipanel('Parent', hF, 'BackgroundColor', 'w', 'BorderWidth', 0, 'Units', 'pixels');

SAxes.hIcons = zeros(length(SIcons), 1);
SImg .hIcons = zeros(length(SIcons), 1);

iStartPos = - SAp.iICONSIZE;
for iI = 1:length(SIcons)
    iStartPos = iStartPos + SAp.iICONPADDING + SAp.iICONSIZE;
    
    dI = double(imread([SPref.sICONPATH, SIcons(iI).Name, '.png'])); % icon file name (.png) has to be equal to icon name
    if size(dI, 3) == 1, dI = repmat(dI, [1 1 3]); end
    SIcons(iI).dImg = dI./255;
    
    SAxes.hIcons(iI) = axes('Parent', SPanels.hMenu, 'Units', 'pixels', 'Position'  , [iStartPos 12 SAp.iICONSIZE SAp.iICONSIZE]); %#ok<LAXES>
    SImg.hIcons(iI) = image(SIcons(iI).dImg, 'Parent', SAxes.hIcons(iI), 'ButtonDownFcn' , @fIconClick);
    axis(SAxes.hIcons(iI), 'off');
    if SIcons(iI).Spacer, iStartPos = iStartPos + SAp.iICONSIZE; end
end
SState.dIconEnd = iStartPos + SAp.iICONPADDING + SAp.iICONSIZE;

STexts.hStatus = uicontrol(... % Create the text element
    'Style'                 ,'Text', ...
    'FontName'              , 'Helvetica Neue', ...
    'FontWeight'            , 'light', ...
    'Parent'                , SPanels.hMenu, ...
    'FontUnits'             , 'normalized', ...
    'FontSize'              , 0.6, ...
    'BackgroundColor'       , 'w', ...
    'ForegroundColor'       , 1 - repmat(SAp.iACTIVE_SCALE, [1 3]), ...
    'HorizontalAlignment'   , 'right', ...
    'Units'                 , 'pixels');

SPanels.hStatus = uipanel('Parent', hF, 'BackgroundColor', SAp.dBGCOLOR, 'BorderWidth', 0, 'Units', 'pixels');
STexts.hUser = uicontrol(... % Create the text element
    'Style'                 ,'Text', ...
    'FontName'              , 'Helvetica Neue', ...
    'FontWeight'            , 'light', ...
    'String'                , '', ...
    'Parent'                , SPanels.hStatus, ...
    'Position'              , [30 5 100 20], ...
    'FontUnits'             , 'normalized', ...
    'FontSize'              , 0.7, ...
    'BackgroundColor'       , SAp.dBGCOLOR, ...
    'ForegroundColor'       , 'w', ...
    'HorizontalAlignment'   , 'left', ...
    'Units'                 , 'pixels');
STexts.hPro = uicontrol(... % Create the text element
    'Style'                 ,'Text', ...
    'FontName'              , 'Helvetica Neue', ...
    'FontWeight'            , 'light', ...
    'String'                , '', ...
    'Parent'                , SPanels.hStatus, ...
    'Position'              , [1 1 1 1], ...
    'FontUnits'             , 'normalized', ...
    'FontSize'              , 0.7, ...
    'BackgroundColor'       , SAp.dBGCOLOR, ...
    'ForegroundColor'       , 'w', ...
    'HorizontalAlignment'   , 'right', ...
    'Units'                 , 'pixels');
STexts.hPrompt = uicontrol(... % Create the text element
    'Style'                 ,'Text', ...
    'FontName'              , 'Helvetica Neue', ...
    'FontWeight'            , 'light', ...
    'String'                , '', ...
    'Parent'                , SPanels.hStatus, ...
    'Position'              , [1 1 1 1], ...
    'FontUnits'             , 'normalized', ...
    'FontSize'              , 0.7, ...
    'BackgroundColor'       , SAp.dBGCOLOR, ...
    'ForegroundColor'       , 'w', ...
    'HorizontalAlignment'   , 'left', ...
    'Units'                 , 'pixels');
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Parse Inputs and determine and create the initial amount of panels
if nargin    
    SVars = load(sProject);
    [SState.sPath] = fileparts(sProject);
    if ~isfield(SVars, 'SProject'), error('Not a valid blindfold project!'); end
    
    SProject = SVars.SProject;
    SState.sPath = SProject.sPath;
    set(hF, 'Name', sprintf('BlindFold %s - [%s]', SAp.sVERSION, SProject.sProject));
end
% -------------------------------------------------------------------------


dI = double(imread([SPref.sICONPATH, 'heart.png']))./255; % icon file name (.png) has to be equal to icon name
dI = imresize(dI, [16 16]);
dI = padarray(dI, [0, 2], 'both');
SAp.dHeartOn = fBlend(SAp.dPANELCOLOR, dI, 'screen');

dI = double(imread([SPref.sICONPATH, 'heart0.png']))./255; % icon file name (.png) has to be equal to icon name
dI = imresize(dI, [16 16]);
dI = padarray(dI, [0, 2], 'both');
SAp.dHeartOff = fBlend(SAp.dPANELCOLOR, dI, 'screen');

dI = double(imread([SPref.sICONPATH, 'id.png']))./255; % icon file name (.png) has to be equal to icon name
dI = imresize(dI, [16 16]);
SAp.dID = fBlend(SAp.dBGCOLOR, dI, 'screen');

dI = double(imread([SPref.sICONPATH, 'info.png']))./255; % icon file name (.png) has to be equal to icon name
dI = imresize(dI, [16 16]);
SAp.dInfo = fBlend(SAp.dBGCOLOR, dI, 'screen');

SAxes.hID = axes('Parent', SPanels.hStatus, 'Units', 'pixels', 'Position', [4, 6, 16, 16]);
SImg .hID = image(SAp.dID, 'Parent', SAxes.hID);
axis(SAxes.hID, 'off');

SAxes.hInfo = axes('Parent', SPanels.hStatus, 'Units', 'pixels', 'Position', [170, 6, 16, 16]);
SImg .hInfo = image(SAp.dInfo, 'Parent', SAxes.hInfo);
axis(SAxes.hInfo, 'off');

csGraphics = {'Bar', 'BarEndL', 'BarEndR', 'BarBG', 'BarBGEnd'};
for iI = 1:length(csGraphics)
    [dI, temp, dAlpha] = imread([SPref.sICONPATH, csGraphics{iI}, '.png']);
    SAp.(['d', csGraphics{iI}]) = cat(3, dI, dAlpha);
end
SAp.dBarBGImg = fBlend(SAp.dBGCOLOR, [SAp.dBarBGEnd, repmat(SAp.dBarBG, [1, 204]), flipdim(SAp.dBarBGEnd, 2)], 'normal');

SAxes.hPro = axes('Parent', SPanels.hStatus, 'Units', 'pixels'); 
SImg.hPro  = image(SAp.dBarBGImg, 'Parent', SAxes.hPro);
axis(SAxes.hPro, 'off');

% -------------------------------------------------------------------------
% Update the figure components
fCreatePanels;
fUpdateActivation; % Acitvate/deactivate some buttons according to the gui state
fResizeFigure(hF, []); % Call the resize function to allign all the gui elements
% =========================================================================

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fCloseGUI (nested in blindfold)
    % * *
    % * * Figure callback
    % * *
    % * * Closes the figure and saves the settings
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fCloseGUI(hObject, eventdata) %#ok<*INUSD> eventdata is repeatedly unused
        if ~isempty(SProject) && ~isempty(SState.sUser)
            fSaveRating(SProject.sProject, SState.sUser, SState.cRating)
        end
                        
        % -----------------------------------------------------------------
        % Save the settings
        SSaveVar.sPath          = SState.sPath;
        SSaveVar.iPosition      = get(hObject, 'Position');
        SSaveVar.lGermanExport  = SPref.lGERMANEXPORT;
        try
            save(SPref.sSaveFilename, 'SSaveVar');
        catch
            warning('Could not save the settings! Is the BLINDFOLD folder protected?');
        end
        % -----------------------------------------------------------------
        delete(hObject); % Bye-bye figure
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fCloseGUI
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fResizeFigure (nested in blindfold)
    % * *
    % * * Figure callback
    % * *
    % * * Re-arranges all the GUI elements after a figure resize
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fResizeFigure(hObject, eventdata)
        % -----------------------------------------------------------------
        % The resize callback is called very early, therefore we have to check
        % if the GUI elements were already created and return if not
        if ~isfield(SPanels, 'hImgFrame'), return, end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Get figure dimensions
        dFigureSize   = get(hF, 'Position');
        dFigureWidth  = dFigureSize(3);
        dFigureHeight = dFigureSize(4);
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Arrange the panels and all their contents
        for iM = 1:SState.iPanels(1)
            for iN = 1:SState.iPanels(2)
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Determine the position of the panel
                iLinInd = (iM - 1).*SState.iPanels(2) + iN;
                dWidth  = round(dFigureWidth / SState.iPanels(2)) - 1;
                dHeight = round((dFigureHeight - SAp.iMENUBARHEIGHT - SAp.iSTATUSBARHEIGHT) / SState.iPanels(1)) - 1;
                dXStart =                 (iN - 1).*(dWidth  + 1) + 2;
                dYStart = (SState.iPanels(1) - iM).*(dHeight + 1) + 2 + SAp.iSTATUSBARHEIGHT;
                if iN == SState.iPanels(2), dWidth  = dFigureWidth                       - dXStart; end
                if iM == 1                , dHeight = dFigureHeight - SAp.iMENUBARHEIGHT - dYStart; end
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Arrange the panels
                set(SPanels.hImgFrame(iLinInd),  'Position', [dXStart, dYStart, dWidth, dHeight]);
                dImgYStart = 1;
                dImgHeight = dHeight - SAp.iTITLEBARHEIGHT;
                set(SPanels.hImg(iLinInd), 'Position', [1, dImgYStart, dWidth, dImgHeight]);
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                set(STexts.hImg(iLinInd), 'Position', [1,  dHeight - SAp.iTITLEBARHEIGHT + 3, dWidth - 10, SAp.iTITLEBARHEIGHT - 3]);
                
                if ~isfield(SAxes, 'hRate'), continue, end
                iStartPos = dWidth - size(SAxes.hRate, 2).*20 - 4;
                set(STexts.hImg(iLinInd), 'Position', [1,  dHeight - SAp.iTITLEBARHEIGHT + 3, iStartPos - 10, SAp.iTITLEBARHEIGHT - 3]);
                for iJ = 1:size(SAxes.hRate, 2)
                    set(SAxes.hRate(iLinInd, iJ), 'Position', [iStartPos, dHeight - SAp.iTITLEBARHEIGHT + 5, 20, 16]);
                    iStartPos = iStartPos + 20;
                end
            end
        end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Arrange the menubar
        dTextWidth = max([dFigureWidth - SState.dIconEnd - 10, 1]);
        set(SPanels.hMenu, 'Position', [1, dFigureHeight - SAp.iMENUBARHEIGHT + 1, dFigureWidth, SAp.iMENUBARHEIGHT - 1]);
        set(STexts.hStatus, 'Position', [SState.dIconEnd + 5, SAp.iICONPADDING, dTextWidth, 22]);
        % -----------------------------------------------------------------
        
        set(SPanels.hStatus, 'Position', [1, 1, dFigureWidth, SAp.iSTATUSBARHEIGHT]);
        set(STexts.hPro, 'Position', [dFigureWidth - 270 5 50 20]);
        set(STexts.hPrompt, 'Position', [190 5 dFigureWidth - 500 20]);
        set(SAxes.hPro, 'Position', [dFigureWidth - 216 7 size(SAp.dBarBGImg, 2) size(SAp.dBarBGImg, 1)]);
        % -------------------------------------------------------------------------
        % Create a beatuiful image for the empty axes
        dWidth  = ceil(dFigureWidth / SState.iPanels(2));
        dHeight = ceil((dFigureHeight - SAp.iMENUBARHEIGHT) / SState.iPanels(1)) - SAp.iTITLEBARHEIGHT;
        SAp.dEmptyImg = fBackgroundImg(dHeight, dWidth);
        % -------------------------------------------------------------------------
        
        fFillPanels;
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fResizeFigure
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fIconClick (nested in blindfold)
    % * *
    % * * Common callback for all buttons in the menubar
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fIconClick(hObject, eventdata)
        % -----------------------------------------------------------------
        % Get the source's (pressed buttton) data and exit if disabled
        iInd = find(SImg.hIcons == hObject);
        if ~SIcons(iInd).Enabled, return, end;
        % -----------------------------------------------------------------
        sActivate = [];
         
        % -----------------------------------------------------------------
        % Distinguish the idfferent button types (normal, toggle, radio)
        switch SIcons(iInd).GroupIndex
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % NORMAL pushbuttons
            case -1
                
                switch(SIcons(iInd).Name)
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % NEW Project
                    case 'doc_new'
                        if ~isempty(SProject) && ~isempty(SState.sUser)
                            fSaveRating(SProject.sProject, SState.sUser, SState.cRating)
                        end
                        
                        SProject = fCreateProject;%([], SState.sPath);
                        if ~SProject.lOK, return, end;   % Dialog aborted
                        
                        save(SProject.sProject, 'SProject');
                        SState.sPath = SProject.sPath;
                        set(hF, 'Name', sprintf('BlindFold %s - [%s]', SAp.sVERSION, SProject.sProject));
                        if ~isempty(SState.sUser)
                            fCreateRating;
                            fUpdateProgress;
                        end
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % LOAD Project
                    case 'folder_open'
                        if ~isempty(SProject) && ~isempty(SState.sUser)
                            fSaveRating(SProject.sProject, SState.sUser, SState.cRating)
                        end
                        
                        [sFilename, sPath] = uigetfile('*.mat', 'Open Project', SState.sPath);
                        if isnumeric(sPath), return, end;   % Dialog aborted
                        
                        SVars = load([sPath, filesep, sFilename]);
                        if ~isfield(SVars, 'SProject'), error('Not a valid blindfold project!'); end
                        
                        SProject = SVars.SProject;
                        SState.sPath = SProject.sPath;
                        set(hF, 'Name', sprintf('BlindFold %s - [%s]', SAp.sVERSION, SProject.sProject));
                        
                        if ~isempty(SState.sUser)
                            if isfield(SVars, SState.sUser)
                                SState.cRating = SVars.(SState.sUser);
                                fUpdateProgress;
                            else
                                fCreateRating;
                                fUpdateProgress;
                            end
                        end
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        
                    case 'info'
                        SVars = load(SProject.sProject);
                        SVars = rmfield(SVars, 'SProject');
                        
                        csUsers = fieldnames(SVars);
                        dCompletion = zeros(length(csUsers), 1);
                        dSum = 0;
                        fprintf(1, '\nStatistics for project ''%s'':\n', SProject.sProject);
                        for i = 1:length(csUsers)
                            csRating = SVars.(csUsers{i});
                            for iJ = 1:length(csRating)
                                dCompletion(i) = dCompletion(i) + nnz(csRating{iJ});
                                if i == 1, dSum = dSum + numel(csRating{iJ}); end
                            end
                            fprintf(1, 'User ''%s'' %3d %% completed!\n', csUsers{i}, round(dCompletion(i)./dSum.*100));
                        end
                        
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % ID: Change user name
                    case 'id'
                        if ~isempty(SProject)
                            if ~isempty(SState.sUser)
                                fSaveRating(SProject.sProject, SState.sUser, SState.cRating)
                            end
                            SVars = load(SProject.sProject);
                            SVars = rmfield(SVars, 'SProject');
                            csUsers = fieldnames(SVars);
                            if(isempty(csUsers))
                                sUser = inputdlg('Name', 'Set current user', 1);
                                if isempty(sUser), return, end;
                                sUser = sUser{1};
                            else
                                sUser = fGetUser(csUsers);
                                if isempty(sUser), return, end;
                            end
                        else
                            sUser = inputdlg('Name', 'Set current user', 1);
                            if isempty(sUser), return, end;
                            sUser = sUser{1};
                        end
                        
                        SState.sUser = sUser;
                        set(STexts.hUser, 'String', sUser);
                        
                        if isempty(SProject), return, end
                        
                        SVars = load(SProject.sProject);
                        if isfield(SVars, SState.sUser)
                            SState.cRating = SVars.(SState.sUser);
                        else
                            fCreateRating;
                        end
                        SState.lReading = false;
                        SData = [];
                        SState.iLastHover = [0, 0];
                        fCreatePanels;
                        fResizeFigure(hF, []);
                        set(STexts.hPrompt, 'String', '');
                        fFillPanels;
                        % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        
                    case 'play'
                        SState.iTestcase = 1;
                        while all(sum(SState.cRating{SState.iTestcase}, 2))
                            SState.iTestcase = SState.iTestcase + 1;
                            if SState.iTestcase > length(SState.cRating)
                                SState.iTestcase = 1;
                                warndlg('This user has already rated all testcases. Starting at the beginning. Rating will overwrite previous ratings!', 'Warning');
                                break
                            end
                        end
                        iRatings = SState.cRating{SState.iTestcase};
                        iRatings = iRatings(SProject.iPatientPermutation, :);
                        SState.iPatient = find(sum(iRatings, 2) == 0, 1, 'first');
                        if isempty(SState.iPatient), SState.iPatient = 1; end
                        SState.lReading = true;
                        fLoadData;
                        fUpdateRatings;
                        
                    case 'stop'
                        fSaveRating(SProject.sProject, SState.sUser, SState.cRating)
                        SState.lReading = false;
                        SData = [];
                        SState.iLastHover = [0, 0];
                        fCreatePanels;
                        fResizeFigure(hF, []);
                        set(STexts.hPrompt, 'String', '');
                        fFillPanels;
                        
                    case 'rewind'
                        fSaveRating(SProject.sProject, SState.sUser, SState.cRating)
                        if SState.iPatient > 1
                            SState.iPatient = SState.iPatient - 1;
                        else
                            SState.iPatient = length(SProject.csPatients);
                            SState.iTestcase = SState.iTestcase - 1;
                        end
                        fLoadData;
                        fUpdateRatings
                        
                        
                    case 'next'
                        fSaveRating(SProject.sProject, SState.sUser, SState.cRating)
                        if SState.iPatient < length(SProject.csPatients)
                            SState.iPatient = SState.iPatient + 1;
                        else
                            SState.iPatient = 1;
                            SState.iTestcase = SState.iTestcase + 1;
                        end
                        fLoadData;
                        fUpdateRatings
                        
                    case 'first'
                        fSaveRating(SProject.sProject, SState.sUser, SState.cRating);
                        SState.iPatient = 1;
                        SState.iTestcase = 1;
                        fLoadData;
                        fUpdateRatings
                        
                    case 'last'
                        fSaveRating(SProject.sProject, SState.sUser, SState.cRating);
                        SState.iPatient = length(SProject.csPatients);
                        SState.iTestcase = length(SProject.STestCases);
                        fLoadData;
                        fUpdateRatings
                        
                    case 'bars'
                        fShowResults(SProject.sProject);
                        
                    otherwise
                end
                % End of NORMAL buttons
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % TOGGLE buttons: Invert the state
            case 0
                SIcons(iInd).Active = ~SIcons(iInd).Active;
                fFillPanels; % Because of link button
                % End of TOGGLE buttons
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
            case 255 % The toolbar
                SState.sTool = SIcons(iInd).Name;
                SIcons(iInd).Active = ~SIcons(iInd).Active;
                sActivate    = SIcons(iInd).Name;
%                 fFillPanels;
        end
        
        % -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        % Common code for all radio groups
        if SIcons(iInd).GroupIndex > 0
            for i = 1:length(SIcons)
                    if SIcons(i).GroupIndex == SIcons(iInd).GroupIndex
                    SIcons(i).Active = strcmp(SIcons(i).Name, sActivate);
                end
            end
        end
        fUpdateActivation();
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fIconClick
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowMouseHoverFcn (nested in blindfold)
    % * *
    % * * Figure callback
    % * *
    % * * The standard mouse move callback. Displays cursor coordinates and
    % * * intensity value of corresponding pixel.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindowMouseHoverFcn(hObject, eventdata)
        if ~isfield(SPanels, 'hImgFrame'), return, end; % Return if called during GUI startup
        
        iAxisInd = fGetPanel();
        if ~iAxisInd
            % -------------------------------------------------------------
            % Cursor is not over a panel -> Check if tooltip has to be shown
            iCursorPos = get(hF, 'CurrentPoint');
            iInd = 0;
            for i = 1:length(SAxes.hIcons);
                dPos = get(SAxes.hIcons(i), 'Position');
                dParentPos = get(get(SAxes.hIcons(i), 'Parent'), 'Position');
                dPos(1:2) = dPos(1:2) + dParentPos(1:2);
                if ((iCursorPos(1) >= dPos(1)) && (iCursorPos(1) < dPos(1) + dPos(3)) && ...
                        (iCursorPos(2) >= dPos(2)) && (iCursorPos(2) < dPos(2) + dPos(4)))
                    iInd = i;
                end
            end
            if iInd
                sText = SIcons(iInd).Tooltip;
                sAccelerator = SIcons(iInd).Accelerator;
                if ~isempty(SIcons(iInd).Modifier), sAccelerator = sprintf('%s+%s', SIcons(iInd).Modifier, SIcons(iInd).Accelerator); end
                if ~isempty(SIcons(iInd).Accelerator), sText = sprintf('%s [%s]', sText, sAccelerator); end
                set(STexts.hStatus, 'String', sText);
            else
                set(STexts.hStatus, 'String', '');
            end
            % -------------------------------------------------------------
            iHover = [0, 0];
        else
            if ~isfield(SAxes, 'hRate'), return, end
            if isempty(SData), return, end

            dCursorPos = get(hF, 'CurrentPoint');
            dPos = get(SAxes.hRate(iAxisInd, 1), 'Position');
            dParentPos = get(get(SAxes.hRate(iAxisInd, 1), 'Parent'), 'Position');
            dCursorPos = dCursorPos - dPos(1:2) - dParentPos(1:2) + [0, 5];
            if any(dCursorPos < 0) || dCursorPos(2) > dPos(4)
                iRating = 0;
            else
                iRating = floor(dCursorPos(1)/dPos(3)) + 1;
                if iRating > SProject.iNRatings, iRating = 0; end
            end
            iHover = [iAxisInd, iRating];
        end
      
        % Mouse cursor exits rating icons: restore the saved value
%         if iHover(1) ~= SState.iLastHover(1) && SState.iLastHover(1)
%             iRating = SState.cRating{SState.iTestcase}(SProject.iPatientPermutation(SState.iPatient), SState.iPermutation(SState.iLastHover(1)));
%             for i = 1:size(SAxes.hRate, 2)
%                 if i <= iRating, set(SImg.hRate(SState.iLastHover(1), i), 'CData', SAp.dHeartOn);
%                 else set(SImg.hRate(SState.iLastHover(1), i), 'CData', SAp.dHeartOff); end
%             end
%         end
%         
%         if iHover(1) && iHover(2) ~= SState.iLastHover(2)
%             iRating = iHover(2);
%             if ~iRating
%                 iRating = SState.cRating{SState.iTestcase}(SProject.iPatientPermutation(SState.iPatient), SState.iPermutation(SState.iLastHover(1)));
%             end
%             for i = 1:size(SAxes.hRate, 2)
%                 if(SState.iLastHover(1) > 0)
%                     if i <= iRating, set(SImg.hRate(SState.iLastHover(1), i), 'CData', SAp.dHeartOn);
%                     else set(SImg.hRate(SState.iLastHover(1), i), 'CData', SAp.dHeartOff); end
%                 end
%             end
%         end
        
        SState.iLastHover = iHover;
        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowMouseHoverFcn
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowButtonDownFcn (nested in blindfold)
    % * *
    % * * Figure callback
    % * *
    % * * Starting callback for mouse button actions.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindowButtonDownFcn(hObject, eventdata)
        iAxisInd = fGetPanel();
        if ~iAxisInd, return, end % Exit if event didn't occurr in a panel
        
        % -----------------------------------------------------------------
        % Save starting parameters
        dPos = get(SAxes.hImg(iAxisInd), 'CurrentPoint');
        SMouse.iStartAxis       = iAxisInd;
        SMouse.iStartPos        = get(hObject, 'CurrentPoint');
        SMouse.dAxesStartPos    = [dPos(1, 1), dPos(1, 2)];
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Backup the display settings of all data
        SMouse.dDrawCenter   = reshape([SData.dDrawCenter], [2, length(SData)]);
        SMouse.dZoomFactor   = [SData.dZoomFactor];
        SMouse.dWindowCenter = [SData.dWindowCenter];
        SMouse.dWindowWidth  = [SData.dWindowWidth];
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Activate the callbacks for drag operations
        set(hObject, 'WindowButtonUpFcn',     @fWindowButtonUpFcn);
        set(hObject, 'WindowButtonMotionFcn', @fWindowMouseMoveFcn);
        % -----------------------------------------------------------------
        
        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowButtonDownFcn
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowMouseMoveFcn (nested in blindfold)
    % * *
    % * * Figure callback
    % * *
    % * * Callback for mouse movement while button is pressed.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindowMouseMoveFcn(hObject, eventdata)
        iAxesInd = fGetPanel();
        if ~iAxesInd, return, end % Exit if event didn't occurr in a panel
        
        % -----------------------------------------------------------------
        % Get some frequently used values
        iD        = get(hF, 'CurrentPoint') - SMouse.iStartPos; % Mouse distance travelled since button down
        dPanelPos = get(SPanels.hImg(SMouse.iStartAxis), 'Position');
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Tool-specific code
        switch SState.sTool

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The NORMAL CURSOR: select, move, zoom, window
            case 'cursor_arrow'  
                switch get(hF, 'SelectionType')

                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Normal, left mouse button -> MOVE operation
                    case 'normal'
                        dD = double(iD)./dPanelPos(3:4); % Scale mouse movement to panel size (since DrawCenter is a relative value)
                        for i = 1:length(SData)
                            dNewPos = SMouse.dDrawCenter(:, i)' + dD; % Calculate new draw center relative to saved one
                            SData(i).dDrawCenter = dNewPos; % Save DrawCenter data
                            if i < 1 || i > length(SPanels.hImg), continue, end % Do not update images outside the figure's scope (will be done with next call of fFillPanels

                            dPos = get(SAxes.hImg(i), 'Position');
                            set(SAxes.hImg(i), 'Position', [dPanelPos(3)*(dNewPos(1)) - dPos(3)/2, dPanelPos(4)*(dNewPos(2)) - dPos(4)/2, dPos(3), dPos(4)]);
                        end
                        % - - - - - - - - - - - - - - - - - - - - - - - - - - -

                        % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        % Shift key or right mouse button -> ZOOM operation
                    case 'alt'
                        for i = 1:length(SData)
                            dZoomFactor = max([0.25, SMouse.dZoomFactor(i).*exp(SPref.dZOOMSENSITIVITY.*iD(2))]);
                            dZoomFactor = min([dZoomFactor, 100]);

                            dStaticCoordinate = SMouse.dAxesStartPos - 0.5;
                            dStaticCoordinate(2) = size(SData(i).dImg, 1) - dStaticCoordinate(2);
                            iFramePos = get(SPanels.hImgFrame(SMouse.iStartAxis), 'Position');
                            dStaticPoint = SMouse.iStartPos - iFramePos(1:2);

                            dStartPoint = dStaticPoint - (dStaticCoordinate).*dZoomFactor + [1.5 1.5];
                            dEndPoint   = dStaticPoint + ([size(SData(i).dImg, 2), size(SData(i).dImg, 1)] - dStaticCoordinate).*dZoomFactor + [1.5 1.5];

                            SData(i).dDrawCenter = (dEndPoint + dStartPoint)./(2.*dPanelPos(3:4)); % Save Draw Center
                            SData(i).dZoomFactor = dZoomFactor; % Save ZoomFactor data

                            if i < 1 || i > length(SPanels.hImg), continue, end % Do not update images outside the figure's scope (will be done with next call of fFillPanels

                            dImageWidth  = double(size(SData(i).dImg, 2)).*dZoomFactor;
                            dImageHeight = double(size(SData(i).dImg, 1)).*dZoomFactor;
                            set(SAxes.hImg(i), 'Position', [dPanelPos(3).*SData(i).dDrawCenter(1) - dImageWidth/2, ...
                                dPanelPos(4).*SData(i).dDrawCenter(2) - dImageHeight/2, ...
                                dImageWidth, dImageHeight]);
                            if i == SMouse.iStartAxis % Show zooming information for the starting axis
                                set(STexts.hStatus, 'String', sprintf('Zoom: %3.1fx', dZoomFactor));
                            end
                        end

                    case 'extend' % Control key or middle mouse button -> WINDOW operation
                        for i = 1:length(SData)
                            SData(i).dWindowWidth  = SMouse.dWindowWidth(i) .*exp(SPref.dWINDOWSENSITIVITY*(-iD(2)));
                            SData(i).dWindowCenter = SMouse.dWindowCenter(i).*exp(SPref.dWINDOWSENSITIVITY*  iD(1));
                            if i < 1 || i > length(SPanels.hImg), continue, end % Do not update images outside the figure's scope (will be done with next call of fFillPanels)
                            if i == SMouse.iStartAxis % Show windowing information for the starting axes
                                set(STexts.hStatus, 'String', sprintf('C: %s, W: %s', num2str(SData(i).dWindowCenter), num2str(SData(i).dWindowWidth)));
                            end
                        end
                        fFillPanels;
                end
                
                % end of the NORMAL CURSOR
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    

            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % The ROTATION tool
            case 'rotate'
                if ~any(abs(iD) > SPref.dROTATION_THRESHOLD), return, end   % Only proceed if action required

%                 iStartSeries = SMouse.iStartAxis + SState.iStartSeries - 1;
                for i = 1:length(SData)
%                     if ~(lLinked || i == iStartSeries || SData(i).iGroupIndex == SData(iStartSeries).iGroupIndex), continue, end % Skip if axes not linked and current figure not active
                    
                    switch get(hObject, 'SelectionType')
                        % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                        % Normal, left mouse button -> volume rotation operation
                        case 'normal'
                            if iD(1) > SPref.dROTATION_THRESHOLD % Moved mouse to left
                                SData(i).iActiveImage = uint16(SMouse.dAxesStartPos(1, 1));
                                iPermutation = [1 3 2]; iFlipdim = 2;
                            end
                            if iD(1) < -SPref.dROTATION_THRESHOLD % Moved mouse to right
                                SData(i).iActiveImage = uint16(size(SData(i).dImg, 2) - SMouse.dAxesStartPos(1, 1) + 1);
                                iPermutation = [1 3 2]; iFlipdim = 3;
                            end
                            if iD(2) > SPref.dROTATION_THRESHOLD
                                SData(i).iActiveImage = uint16(size(SData(i).dImg, 1) - SMouse.dAxesStartPos(1, 2) + 1);
                                iPermutation = [3 2 1]; iFlipdim = 3;
                            end
                            if iD(2) < -SPref.dROTATION_THRESHOLD
                                SData(i).iActiveImage = uint16(SMouse.dAxesStartPos(1, 2));
                                iPermutation = [3 2 1]; iFlipdim = 1;
                            end
                            
                        % - - - - - - - - - - - - - - - - - - - - - - - - -
                        % Shift key or right mouse button -> rotate in-plane
                        case 'alt'
                            if any(iD > SPref.dROTATION_THRESHOLD)
                                iPermutation = [2 1 3]; iFlipdim = 2;
                            end
                            if any(iD < -SPref.dROTATION_THRESHOLD)
                                iPermutation = [2 1 3]; iFlipdim = 1;
                            end
                        % - - - - - - - - - - - - - - - - - - - - - - - - -
                    end
                    % Switch statement
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    
                    % - - - - - - - - - - - - - - - - - - - - - - - - - - -
                    % Apply the transformation
                    if(size(SData(i).dImg,4) > 1)
                        for iGate=1:size(SData(i).dImg,4)
                            SData(i).dImg(:,:,:,iGate) =  flipdim(permute(SData(i).dImg(:,:,:,iGate),  iPermutation), iFlipdim);
                        end
                    else
                        SData(i).dImg =  flipdim(permute(SData(i).dImg,  iPermutation), iFlipdim);
                    end
                    set(hObject, 'WindowButtonMotionFcn', @fWindowMouseHoverFcn);
                    
                    % - - - - - - - - - - - - - - - - - - - - - - -
                    % Limit active image range to image dimensions
                    if SData(i).iActiveImage < 1, SData(i).iActiveImage = 1; end
                    if SData(i).iActiveImage > size(SData(i).dImg, 3), SData(i).iActiveImage = size(SData(i).dImg, 3); end
                end
                % Loop over the data
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
            % END of the rotate tool
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        end
        % end of the TOOL switch statement
        % -----------------------------------------------------------------
        fFillPanels();
        drawnow expose
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowMouseMoveFcn
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fWindowButtonUpFcn (nested in blindfold)
    % * *
    % * * Figure callback
    % * *
    % * * End of mouse operations.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fWindowButtonUpFcn(hObject, eventdata)
        iAxisInd = fGetPanel();
        if ~iAxisInd, return, end % Exit if Event didn't occurr in a panel
        
        if isfield(SAxes, 'hRate') % update hearts
            if ~isempty(SData)
                dCursorPos = get(hF, 'CurrentPoint');
                dPos = get(SAxes.hRate(iAxisInd, 1), 'Position');
                dParentPos = get(get(SAxes.hRate(iAxisInd, 1), 'Parent'), 'Position');
                dCursorPos = dCursorPos - dPos(1:2) - dParentPos(1:2) + [0, 5];
                if dCursorPos(1) < 0 && dCursorPos(2) > 0 % update rating to zero
%                     iPatient = SProject.iPatientPermutation(SState.iPatient);
%                     iRating = SState.cRating{SState.iTestcase}(iPatient, :);
%                     iRating = iRating(SState.iPermutation);
%                     iInd = find(~iRating, 1, 'first');
                    fRate([], [iAxisInd, 0]);
                elseif(all(dCursorPos > 0) && dCursorPos(2) < dPos(4))
                    iCurrRating = floor(dCursorPos(1)/dPos(3)) + 1;
                    if iCurrRating > SProject.iNRatings, iCurrRating = 0; end
%                     iPatient = SProject.iPatientPermutation(SState.iPatient);
%                     iRating = SState.cRating{SState.iTestcase}(iPatient, :);
%                     iRating = iRating(SState.iPermutation);
%                     iInd = find(~iRating, 1, 'first');
                    fRate([], [iAxisInd, iCurrRating]);
                end  
            end
        end
        
        % -----------------------------------------------------------------
        % Stop the operation by disabling the corresponding callbacks
        set(hF, 'WindowButtonMotionFcn'    ,@fWindowMouseHoverFcn);
        set(hF, 'WindowButtonUpFcn'        ,'');
        set(STexts.hStatus, 'String', '');
        % -----------------------------------------------------------------
        
        fUpdateActivation();
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fWindowButtonUpFcn
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fKeyPressFcn (nested in blindfold)
    % * *
    % * * Figure callback
    % * *
    % * * Callback for keyboard actions.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fKeyPressFcn(hObject, eventdata)
        % -----------------------------------------------------------------
        % Bail if only a modifier has been pressed
        switch eventdata.Key
            case {'shift', 'control', 'alt'}, return
        end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Get the modifier (shift, cntl, alt) keys and determine whether
        % the control key was pressed
        csModifier = eventdata.Modifier;
        sModifier = '';
        for i = 1:length(csModifier)
            if strcmp(csModifier{i}, 'shift'  ), sModifier = 'Shift'; end
            if strcmp(csModifier{i}, 'control'), sModifier = 'Cntl'; end
            if strcmp(csModifier{i}, 'alt'    ), sModifier = 'Alt'; end
        end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Look for buttons with corresponding accelerators/modifiers
        for i = 1:length(SIcons)
            if strcmp(SIcons(i).Accelerator, eventdata.Key) && ...
                    strcmp(SIcons(i).Modifier, sModifier)
                fIconClick(SImg.hIcons(i), eventdata);
            end
        end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Functions not implemented by buttons
        switch eventdata.Key
            case {'numpad1', 'leftarrow'} % Image up
                fChangeImage(hObject, -1);
                
            case {'numpad2', 'rightarrow'} % Image down
                fChangeImage(hObject, 1);
                
            case {'numpad4', 'downarrow'} % Gate down
                fChangeGate(hObject, -1);
                
            case {'numpad5', 'uparrow'} % Gate up
                fChangeGate(hObject, 1);
                
        end
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Rating using number keys
        if isempty(SProject), return, end
        iNum = str2double(eventdata.Key);
        if ~isnan(iNum)
            if iNum <= SProject.iNRatings && iNum > 0
                iPatient = SProject.iPatientPermutation(SState.iPatient);
                iRating = SState.cRating{SState.iTestcase}(iPatient, :);
                iRating = iRating(SState.iPermutation);
                iInd = find(~iRating, 1, 'first');
                if ~isempty(iInd), fRate([], [iInd, iNum]); end
            end
        end
        % -----------------------------------------------------------------
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fKeyPressFcn
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fChangeImage (nested in blindfold)
    % * *
    % * * Change image index of all series (if linked) or all selected
    % * * series.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fChangeImage(hObject, iCnt)
        
        if isstruct(iCnt), iCnt = iCnt.VerticalScrollCount; end % Origin is mouse wheel
        if isobject(iCnt), iCnt = iCnt.VerticalScrollCount; end % From 2014b on
        % -----------------------------------------------------------------
        % Loop over all data (visible or not)
        for iSeriesInd = 1:length(SData)
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Calculate new image index and make sure it's not out of bounds
            iNewImgInd = SData(iSeriesInd).iActiveImage + iCnt;
            iNewImgInd = max([iNewImgInd, 1]);
            iNewImgInd = min([iNewImgInd, size(SData(iSeriesInd).dImg, 3)]);
            SData(iSeriesInd).iActiveImage = iNewImgInd;
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
        end
        fFillPanels;
        % -----------------------------------------------------------------
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fChangeImage
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
     % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fChangeGate (nested in blindfold)
    % * *
    % * * Change gate index of all series (if linked) or all selected
    % * * series.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fChangeGate(hObject, iCnt)
        
        % -----------------------------------------------------------------
        % Loop over all data (visible or not)
        for iSeriesInd = 1:length(SData)
            
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            % Calculate new image index and make sure it's not out of bounds
            iNewImgInd = SData(iSeriesInd).iActiveGate + iCnt;
            iNewImgInd = max([iNewImgInd, 1]);
            iNewImgInd = min([iNewImgInd, size(SData(iSeriesInd).dImg, 4)]);
            SData(iSeriesInd).iActiveGate = iNewImgInd;
            % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
        end
        fFillPanels;
        % -----------------------------------------------------------------
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fChangeGate
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fFillPanels (nested in blindfold)
    % * *
    % * * Display the current data in all panels.
    % * * The holy grail of Blindfold!
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fFillPanels
        for i = 1:length(SPanels.hImgFrame)
            if i <= length(SData) % Panel not empty
                
                iDataInd = SState.iPermutation(i);
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Get the image data, do windowing and apply colormap
                dImg = SData(iDataInd).dImg(:,:,SData(iDataInd).iActiveImage,SData(iDataInd).iActiveGate);
                dMin = SData(iDataInd).dWindowCenter - 0.5.*SData(iDataInd).dWindowWidth;
                dMax = SData(iDataInd).dWindowCenter + 0.5.*SData(iDataInd).dWindowWidth;
                dImg = dImg - dMin;
                iImg = uint8(dImg./(dMax - dMin).*255) + 1;
                if(SProject.STestCases(SState.iTestcase).ImageType == 0) % MR
                    dColormap = gray(256);
                else % PET
                    dColormap = 1-gray(256);
                end
                dImg = reshape(dColormap(iImg, :), [size(iImg, 1) ,size(iImg, 2), 3]);
                set(SImg.hImg(i), 'CData', dImg);
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Handle zoom and shift
                dPos = get(SPanels.hImg(i), 'Position');
                dDim = [size(dImg, 2), size(dImg, 1)]; % Swap x and y
                dSize = dDim.*SData(iDataInd).dZoomFactor;
                set(SAxes.hImg(i), ...
                    'Position', [SData(iDataInd).dDrawCenter.*dPos(3:4) - dSize./2, dSize], ...
                    'XLim'    , [0.5 dDim(1) + 0.5], ...
                    'YLim'    , [0.5 dDim(2) + 0.5]);
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                set(SImg.hRate(i, :), 'Visible', 'on');
                if i == 1 && SProject.STestCases(SState.iTestcase).iReference
                    set(STexts.hImg(i), 'String', 'Reference', 'Visible', 'on');
                else
                    set(STexts.hImg(i), 'String', '', 'Visible', 'on');
                end
                
            else % Panel is empty
                
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                % Set image to the background image (RGB)
                set(SImg.hImg(i), 'CData', SAp.dEmptyImg);
                dXDim = size(SAp.dEmptyImg, 2);
                dYDim = size(SAp.dEmptyImg, 1);
                set(SAxes.hImg(i), 'Position', [1 1 dXDim, dYDim], 'XLim', [0.5 dXDim + 0.5], 'YLim', [0.5 dYDim + 0.5]);
                if isfield(SImg, 'hRate'), set(SImg.hRate(i, :), 'Visible', 'off'); end
                set(STexts.hImg(i), 'Visible', 'off');
                % - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fFillPanels
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fCreatePanels (nested in blindfold)
    % * *
    % * * Create the panels and its child object.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fCreatePanels
        % -----------------------------------------------------------------
        % Delete panels and their handles if necessary
        if isfield(SPanels, 'hImgFrame')
            if length(SData) == length(SPanels.hImg), return, end
            
            delete(SPanels.hImgFrame); % Deletes hImgFrame and its children
            SPanels = rmfield(SPanels, {'hImgFrame', 'hImg'});
            STexts  = rmfield(STexts,  'hImg');
            SAxes   = rmfield(SAxes,   'hImg');
            SImg    = rmfield(SImg,    'hImg');
            if isfield(SAxes, 'hRate'), SAxes = rmfield(SAxes, 'hRate'); end
            if isfield(SImg, 'hRate'), SImg = rmfield(SImg, 'hRate'); end
        end
        % -----------------------------------------------------------------
        
        if isempty(SData)
            SState.iPanels = [1, 1];
        else
            iNumImages = length(SData);
            dRoot = sqrt(iNumImages);
            iPanelsN = ceil(dRoot);
            iPanelsM = ceil(dRoot);
            while iPanelsN*iPanelsM >= iNumImages
                iPanelsN = iPanelsN - 1;
            end
            iPanelsN = iPanelsN + 1;
            iPanelsN = min([4, iPanelsN]);
            iPanelsM = min([4, iPanelsM]);
            SState.iPanels = [iPanelsN, iPanelsM];
        end
            
        % -----------------------------------------------------------------
        % For each panel create panels, axis, image and text objects
        for i = 1:prod(SState.iPanels)
            SPanels.hImgFrame(i) = uipanel(...
                'Parent'                , hF, ...
                'BackgroundColor'       , SAp.dBGCOLOR, ...
                'BorderWidth'           , 0, ...
                'BorderType'            , 'line', ...
                'Units'                 , 'pixels');
            SPanels.hImg(i) = uipanel(...
                'Parent'                , SPanels.hImgFrame(i), ...
                'BackgroundColor'       , 'k', ...
                'BorderWidth'           , 0, ...
                'Units'                 , 'pixels');
            SAxes.hImg(i) = axes(...
                'Parent'                , SPanels.hImg(i), ...
                'Units'                 , 'pixels');
            SImg.hImg(i) = image(zeros(1, 'uint8'), ...
                'Parent'                , SAxes.hImg(i), ...
                'HitTest'               , 'off');
            STexts.hImg(i) = uicontrol('Style', 'text',...
                'String'                , '', ...
                'Parent'                , SPanels.hImgFrame(i), ...
                'BackgroundColor'       , SAp.dBGCOLOR, ...
                'ForegroundColor'       , 'w', ...
                'HorizontalAlignment'   , 'left', ...
                'FontUnits'             , 'normalized', ...
                'FontSize'              , 1);
            
            if ~isempty(SProject)
                for iJ = 1:SProject.iNRatings
                    SAxes.hRate(i, iJ) = axes('Parent', SPanels.hImgFrame(i),'Units', 'pixels');
                    SImg .hRate(i, iJ) = image(SAp.dHeartOff, 'Parent', SAxes.hRate(i, iJ), 'ButtonDownFcn', @fRate);
                end
            end
            
        end % of loop over pannels
        % -----------------------------------------------------------------
        
        axis(SAxes.hImg, 'off');
        if isfield(SAxes, 'hRate'), axis(SAxes.hRate(:), 'off'); end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fCreatePanels
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    function fCreateRating
        fprintf(1, 'Creating new user rating.\n');
        for i = 1:length(SProject.STestCases)
            SState.cRating{i} = zeros(length(SProject.csPatients), length(SProject.STestCases(i).csData));
        end
    end
    
    function fRate(hObject, eventdata)
        if ishandle(hObject)
            [iPanel, iRating] = ind2sub(size(SImg.hRate), find(hObject == SImg.hRate));
        else
            iPanel  = eventdata(1);
            iRating = eventdata(2);
        end
        lIncomplete = any(SState.cRating{SState.iTestcase}(SProject.iPatientPermutation(SState.iPatient), :) == 0);
        SState.cRating{SState.iTestcase}(SProject.iPatientPermutation(SState.iPatient), SState.iPermutation(iPanel)) = iRating;
        fUpdateRatings;
        fUpdateProgress;
        drawnow;
        
        if ~fIsOn('auto'), return, end
        if lIncomplete && ~any(SState.cRating{SState.iTestcase}(SProject.iPatientPermutation(SState.iPatient), :) == 0)
            if SState.iPatient < length(SProject.csPatients) || SState.iTestcase < length(SProject.STestCases)
                iInd = strcmp({SIcons.Name}, 'next');
            else
                iInd = strcmp({SIcons.Name}, 'stop');
            end
            fIconClick(SImg.hIcons(iInd), []);
        end
    end

    function fUpdateRatings
        for iAxis = 1:length(SData)
            iRating = SState.cRating{SState.iTestcase}(SProject.iPatientPermutation(SState.iPatient), SState.iPermutation(iAxis));
            for i = 1:size(SAxes.hRate, 2)
                if i <= iRating, set(SImg.hRate(iAxis, i), 'CData', SAp.dHeartOn);
                else set(SImg.hRate(iAxis, i), 'CData', SAp.dHeartOff); end
            end
        end
    end

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fUpdateActivation (nested in blindfold)
    % * *
    % * * Set the activation and availability of some switches according to
    % * * the GUI state.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fUpdateActivation
        % -----------------------------------------------------------------
        % Update states of some menubar buttons according to panel selection
        csLabels = {SIcons.Name};
        SIcons(strcmp(csLabels, 'info')).Enabled    = ~isempty(SProject);
        SIcons(strcmp(csLabels, 'bars')).Enabled    = ~isempty(SProject);
        SIcons(strcmp(csLabels, 'play')).Enabled    = ~isempty(SProject) && ~isempty(SState.sUser) && ~SState.lReading;
        SIcons(strcmp(csLabels, 'stop')).Enabled    = SState.lReading;
        SIcons(strcmp(csLabels, 'rewind')).Enabled  = SState.lReading && ~(SState.iPatient == 1 && SState.iTestcase == 1);
        SIcons(strcmp(csLabels, 'next')).Enabled    = SState.lReading && ~(SState.iPatient == length(SProject.csPatients) && SState.iTestcase == length(SProject.STestCases));
        SIcons(strcmp(csLabels, 'last')).Enabled    = SState.lReading && ~(SState.iPatient == length(SProject.csPatients) && SState.iTestcase == length(SProject.STestCases));
        SIcons(strcmp(csLabels, 'first')).Enabled   = SState.lReading && ~(SState.iPatient == 1 && SState.iTestcase == 1);
        % -----------------------------------------------------------------
        
        % -----------------------------------------------------------------
        % Treat the menubar items
        dScale = SAp.iACTIVE_SCALE.*ones(length(SIcons));
        dScale(~[SIcons.Enabled]) = SAp.iDISABLED_SCALE;
        dScale( [SIcons.Enabled] & ~[SIcons.Active]) = SAp.iINACTIVE_SCALE;
        for i = 1:length(SIcons) set(SImg.hIcons(i), 'CData', 1 - SIcons(i).dImg.*dScale(i)); end
        % -----------------------------------------------------------------
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fUpdateActivation
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


    function fUpdateProgress
        dCompletion = 0;
        dSum = 0;
        for i = 1:length(SState.cRating)
            dCompletion = dCompletion + nnz(any(SState.cRating{i}'));
            dSum = dSum + size(SState.cRating{i}, 1);
        end
        dCompletion = dCompletion./dSum;
        
        dI = padarray([SAp.dBarEndL, repmat(SAp.dBar, [1, round(dCompletion.*200)]), SAp.dBarEndR], [0 2 0], 'pre');
        
        dI = padarray(dI, [0 size(SAp.dBarBGImg, 2) - size(dI, 2), 0], 'post');
        set(SImg.hPro, 'CData', fBlend(SAp.dBarBGImg, dI, 'normal'));
        
        set(STexts.hPro, 'String', sprintf('%3d %%', round(dCompletion.*100)));
    end

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fLoadData (nested in blindfold)
    % * *
    % * * Load data for current patient and testcase
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fLoadData
        SData = []; % clear data
        set(hF, 'Pointer', 'watch'); drawnow;
        dPos = get(hF,'Position');
        dLoadSize = [480, 200];
        hLoadFig = figure('Color','white', 'Menu','none', 'Position', [dPos(1)+round((dPos(3)-dLoadSize(1))/2), dPos(2)+round((dPos(4)-dLoadSize(2))/2), dLoadSize(1), dLoadSize(2)]);
        text(0.5, 0.7, 'Loading data...', 'FontSize', 50, 'Color','k', 'HorizontalAlignment','Center', 'VerticalAlignment','Middle');
        text(0.5, 0.3, 'Please wait!', 'FontSize', 50, 'Color','k', 'HorizontalAlignment','Center', 'VerticalAlignment','Middle');     
        hLoadAxes = findall(hLoadFig,'type','axes');
        set(hLoadAxes,'Color','white'); set(hLoadAxes,'XColor','white'); set(hLoadAxes,'YColor','white'); drawnow;
        
        csPatient = SProject.csPatients{SProject.iPatientPermutation(SState.iPatient)};
        STestcase = SProject.STestCases(SState.iTestcase);
        sPath = [SProject.sStudyPath, filesep, csPatient];
        
        l4D = false;
        
        for i = 1:length(STestcase.csData)
            sThisPath = [sPath, filesep, STestcase.csData{i}];
            
            if exist(sThisPath, 'dir') % A directory: Eith  er images or DICOMs
                dImg = fOpenFolder(sThisPath);
                
            else % A File: Images, DICOMS, mat, GIPL, NifTy
                [temp, sFile, sExt] = fileparts(sThisPath);
                switch(lower(sExt))
                    
                    case '.mat'
                        SInfo = whos('-file', sThisPath);
                        SDat = load(sThisPath);
                        dImg = SDat.(SInfo(1).name);
                        
                    case '.gipl'
                        dImg = fGIPLRead(sThisPath);
                        
                    case '.nii'
                        dImg = fNifTyRead(sThisPath);
                        
                    case {'.jpg', '.jpeg', '.tif', '.tiff', '.gif', '.bmp', '.png'}
                        dImg = imread(sPath);
                        
                    otherwise
                end
            end
            
            dImg(isnan(dImg)) = 0;
            dImg = double(dImg);
            if ~isreal(dImg), dImg = abs(dImg); end
            
            iInd = length(SData) + 1;
            SData(iInd).dImg = dImg;
            if(size(dImg,4) > 1), l4D = true; end
            dMin = min(SData(iInd).dImg(:));
            dMax = max(SData(iInd).dImg(:));
            SData(iInd).dWindowCenter = (dMax + dMin)./2;
            SData(iInd).dWindowWidth  = dMax - dMin;
            SData(iInd).dZoomFactor = 1;
            SData(iInd).dDrawCenter = [0.5 0.5];
            SData(iInd).iActiveImage = round(size(dImg, 3)./2);
            SData(iInd).iActiveGate = 1;
            SData(iInd).sName = STestcase.csData{i};
        end
        
        csLabels = {SIcons.Name};
        if(l4D)
            SIcons(strcmp(csLabels, '4d')).Enabled = true;
            SIcons(strcmp(csLabels, '4d')).Active = true;
        else
            SIcons(strcmp(csLabels, '4d')).Enabled = false;
            SIcons(strcmp(csLabels, '4d')).Active = false;
        end      
        
        fUpdateActivation;
        fGetPermutation;
        fCreatePanels;
        fResizeFigure(hF, []);
        fFillPanels;
        
        for iP=1:size(SImg.hRate,1)% reset hearts
            for iH=1:size(SImg.hRate,2)
                set(SImg.hRate(iP, iH), 'CData', SAp.dHeartOff);
            end
        end
        
        set(STexts.hPrompt, 'String', STestcase.sPrompt);
        close(hLoadFig);
        set(hF, 'Pointer', 'arrow');
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fLoadData
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fOpenFolder (nested in blindfold)
    % * *
    % * * Load a dataset from folder. Either images of DICOMS
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function dImg = fOpenFolder(sPath)
        SDir = dir(sPath);
        SDir = SDir(~[SDir.isdir]);
        
        csExt = cell(size(SDir));
        for i = 1:length(SDir)
            [temp, sFile, sExt] = fileparts(SDir(i).name);
            csExt{i} = sExt;
        end
        csExtensions = unique(csExt);
        iHist = zeros(length(csExtensions));
        for i = 1:length(iHist)
            iHist(i) = nnz(strcmp(csExt, csExtensions{i}));
        end
        [iMax, iInd] = max(iHist);
        sExt = csExtensions{iInd};
        
        SDir = SDir(strcmp(csExt, sExt));
        if any(strcmp({'.jpg', '.jpeg', '.tif', '.tiff', '.gif', '.bmp', '.png'}, sExt))
            dFirstImg = imread([sPath, SDir(1).name]);
            iFirstSize = size(dFirstImg);
            dImg = zeros([iFirstSize, length(SDir)]);
            dImg(:,:,1) = dFirstImg;
            if length(SDir) > 1
                for i = 2:length(SDir)
                    dImg(:,:,i) = imread([sPath, SDir(i).name]);
                end
            end
        else
            try
                iInd = 1;
                for i = 1:length(SDir)
                    dThisImg = [];
                    dThisImg = dicomread([sPath, filesep, SDir(i).name]); 
                    [~,msgID] = lastwarn();
                    if(strcmp(msgID,'images:dicomparse:shortImport')), error('Matlab DICOM read'); end

                    if ~isempty(dThisImg)
                        dImg(:,:,iInd) = dThisImg;
                        iInd = iInd + 1;
                    end
                end
            catch % if DICOM header is modified
                dImg = fReadDICOM(sPath);
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fOpenFolder
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fGetPermutation (nested in blindfold)
    % * *
    % * * Get a permutation vector for the current data
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function fGetPermutation
        SState.iPermutation = randperm(length(SProject.STestCases(SState.iTestcase).csData));
        iReference = SProject.STestCases(SState.iTestcase).iReference;
        if iReference % If reference exists, make sure is the first entry
            SState.iPermutation(SState.iPermutation == iReference) = SState.iPermutation(1);
            SState.iPermutation(1) = iReference;
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGetPermutation
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fGetPanel (nested in blindfold)
    % * *
    % * * Determine the panelnumber under the mouse cursor. Returns 0 if
    % * * not over a panel at all.
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function iPanelInd = fGetPanel()
        iCursorPos = get(hF, 'CurrentPoint');
        iPanelInd = uint8(0);
        for i = 1:min([length(SPanels.hImg), length(SData)])
            dPos = get(SPanels.hImgFrame(i), 'Position');
            if ((iCursorPos(1) >= dPos(1)) && (iCursorPos(1) < dPos(1) + dPos(3)) && ...
                    (iCursorPos(2) >= dPos(2)) && (iCursorPos(2) < dPos(2) + dPos(4)))
                iPanelInd = uint8(i);
            end
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fGetPanel
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION fIsOn (nested in blindfold)
    % * *
    % * * Determine whether togglebutton is active
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function lOn = fIsOn(sTag)
        lOn = SIcons(strcmp({SIcons.Name}, sTag)).Active;
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fIsOn
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fBackgroundImg (nested in blindfold)
    % * *
    % * * Create a funky image for empty panels
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function dImg = fBackgroundImg(dHeight, dWidth)
 
        dWidth  = ceil(dWidth./16);
        dHeight = ceil(dHeight./16);
        dImg = 0.9 + 0.2.*rand(dHeight, dWidth);
        dImg = fReplicate(dImg, 4);
        
        dImg = imfilter(dImg, [0 -1 0; -1 5 -1; 0 -1 0], 'circular', 'same');
        dImg = dImg.*repmat(linspace(1, 0.8, size(dImg, 1))', [1, size(dImg, 2)]);
        
        dImg = repmat(dImg, [1 1 3]);
        dImg = dImg.*repmat(permute(SAp.dBGCOLOR, [1 3 2]) , [size(dImg, 1), size(dImg, 2), 1]);
        dImg(dImg > 1.0) = 1.0;
        dImg(dImg < 0.0) = 0.0;
        
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fBackgroundImg
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fReplicate (nested in blindfold)
    % * *
    % * * Scale image by power of 2 by nearest neighbour interpolation
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function dImgOut = fReplicate(dImg, iIter)
        dImgOut = zeros(2.*size(dImg));
        dImgOut(1:2:end, 1:2:end) = dImg;
        dImgOut(2:2:end, 1:2:end) = dImg;
        dImgOut(1:2:end, 2:2:end) = dImg;
        dImgOut(2:2:end, 2:2:end) = dImg;
        iIter = iIter - 1;
        if iIter > 0, dImgOut = fReplicate(dImgOut, iIter); end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fReplicate
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fBlend (nested in blindfold)
    % * *
    % * * Blend two images with alpha map
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function dOut = fBlend(dBot, dTop, sMode, dAlpha)
        
        %% Parse the inputs
        if nargin < 4, dAlpha = 1.0; end % Top is fully opaque
        if nargin < 3, sMode = 'overlay'; end
        if nargin < 2, error('At least 2 input arguments required!'); end
        if isa(dBot, 'uint8'), dBot = double(dBot)./255; end
        if isa(dTop, 'uint8'), dTop = double(dTop)./255; end
        
        %% Check Inputs
        dTopSize = [size(dTop, 1), size(dTop, 2), size(dTop, 3), size(dTop, 4)];
        
        % Check if background is monochrome
        if numel(dBot) == 1 % grayscale background
            dBot = dBot.*ones(dTopSize);
        end
        if numel(dBot) == 3 % rgb background color
            dBot = repmat(permute(dBot(:), [2 3 1]), [dTopSize(1), dTopSize(2), 1, dTopSize(4)]);
        end
        
        dBotSize = [size(dBot, 1), size(dBot, 2), size(dBot, 3), size(dBot, 4)];
        if dBotSize(3) ~= 1 && dBotSize(3) ~= 3, error('Bottom layer must be either grayscale or RGB!'); end
        if dTopSize(3) > 4, error('Size of 3rd top layer dimension must not exceed 4!'); end
        if any(dBotSize(1, 2) ~= dTopSize(1, 2)), error('Size of image data does not match'); end
        
        if dBotSize(4) ~= dTopSize(4)
            if dBotSize(4) > 1 && dTopSize(4) > 1, error('4th dimension of image data mismatch!'); end
            
            if dBotSize(4) == 1, dBot = repmat(dBot, [1, 1, 1, dTopSize(4)]); end
            if dTopSize(4) == 1, dTop = repmat(dTop, [1, 1, 1, dBotSize(4)]); end
        end
        
        %% Handle the alpha map
        if dTopSize(3) == 2 || dTopSize(3) == 4 % Alpha channel included
            dAlpha = dTop(:,:,end, :);
            dTop   = dTop(:,:,1:end-1,:);
        else
            if isscalar(dAlpha)
                dAlpha = dAlpha.*ones(dTopSize(1), dTopSize(2), 1, dTopSize(4));
            else
                dAlphaSize = [size(dAlpha, 1), size(dAlpha, 2), size(dAlpha, 3), size(dAlpha, 4)];
                if any(dAlphaSize(1:2) ~= dTopSize(1:2)), error('Top layer alpha map dimension mismatch!'); end
                if dAlphaSize(3) > 1, error('3rd dimension of alpha map must have size 1!'); end
                if dAlphaSize(4) > 1
                    if dAlphaSize(4) ~= dTopSize(4), error('Alpha map dimension mismatch!'); end
                else
                    dAlpha = repmat(dAlpha, [1, 1, 1, dTopSize(4)]);
                end
            end
        end
        
        %% Bring data into the right format
        dMaxDim = max([size(dBot, 3), size(dTop, 3)]);
        if dMaxDim > 2, lRGB = true; else lRGB = false; end
        
        if lRGB && dBotSize(3) == 1, dBot = repmat(dBot, [1, 1, 3, 1]); end
        if lRGB && dTopSize(3) == 1, dTop = repmat(dTop, [1, 1, 3, 1]); end
        if lRGB, dAlpha = repmat(dAlpha, [1, 1, 3, 1]); end
        
        %% Check Range
        dBot = fCheckRange(dBot);
        dTop = fCheckRange(dTop);
        dAlpha = fCheckRange(dAlpha);
        
        %% Do the blending
        switch lower(sMode)
            case 'normal',      dOut = dTop;
            case 'multiply',    dOut = dBot.*dTop;
            case 'screen',      dOut = 1 - (1 - dBot).*(1 - dTop);
            case 'overlay'
                lMask = dBot < 0.5;
                dOut = 1 - 2.*(1 - dBot).*(1 - dTop);
                dOut(lMask) = 2.*dBot(lMask).*dTop(lMask);
            case 'hard_light'
                lMask = dTop < 0.5;
                dOut = 1 - 2.*(1 - dBot).*(1 - dTop);
                dOut(lMask) = 2.*dBot(lMask).*dTop(lMask);
            case 'soft_light',  dOut = (1 - 2.*dTop).*dBot.^2 + 2.*dTop.*dBot; % pegtop
            case 'darken',      dOut = min(cat(4, dTop, dBot), [], 4);
            case 'lighten',     dOut = max(cat(4, dTop, dBot), [], 4);
            otherwise,          error('Unknown blend mode ''%s''!', sMode);
        end
        dOut = dAlpha.*dOut + (1 - dAlpha).*dBot;
        
        dOut(dOut > 1) = 1;
        dOut(dOut < 0) = 0;
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fBlend
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * NESTED FUNCTION fCheckRange (nested in blindfold)
    % * *
    % * * Checks for fundamental range of data and clips if necessary
    % * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function dData = fCheckRange(dData)
        if any(dData(:) > 1) || any(dData(:) < 0)
            dData(dData < 0) = 0;
            dData(dData > 1) = 1;
        end
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION fCheckRange
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
  
end
% =========================================================================
% *** END FUNCTION blindfold (and its nested functions)
% =========================================================================



% =========================================================================
% *** FUNCTION fSaveRating
% ***
% *** Save the latest project changes. Needs to be outside of the blindfold
% *** function due to the dynamic variable assignment.
% ***
% =========================================================================
function fSaveRating(sFile, sUser, cData)
    eval(sprintf('%s = cData;', sUser));
    save(sFile, sUser, '-append');
end
% =========================================================================
% *** END FUNCTION fSaveRating
% =========================================================================



function fShowResults(sFile)

hA = [];

SVars = load(sFile);
SProject = SVars.SProject;
SVars = rmfield(SVars, 'SProject');

csUsers = fieldnames(SVars);
dCompletion = zeros(length(csUsers), 1);
dSum = 0;
for i = 1:length(csUsers)
    csRating = SVars.(csUsers{i});
    for iJ = 1:length(csRating)
        dCompletion(i) = dCompletion(i) + nnz(csRating{iJ});
        if i == 1, dSum = dSum + numel(csRating{iJ}); end
    end
end
lComplete = dCompletion == dSum;
csUsers = csUsers(lComplete);

csTestcases = cell(length(SProject.STestCases), 1);
for iI = 1:length(SProject.STestCases)
    csTestcases{iI} = sprintf('Testcase %d', iI);
end

hF = figure;
hCombo = uicontrol('Style', 'popupmenu', 'String', csTestcases, 'Units', 'pixels', 'Position', [1 1 100 24], 'Callback', @fUpdate);
hOption = uicontrol('Style', 'checkbox', 'String', 'Only Show Mean', 'Units', 'pixels', 'Position', [120 6 200 18], 'Callback', @fUpdate);
fDrawResults(1, 0);

    function fUpdate(hObject, eventdata)
        fDrawResults(get(hCombo, 'Value'), get(hOption, 'Value'));
    end

    function fDrawResults(iTestcase, lOnlyMean)
        if ~isempty(hA), delete(hA); end
        
        dMean = zeros(length(csUsers), length(SProject.STestCases(iTestcase).csData));
        for iI = 1:length(csUsers)
            csData = SVars.(csUsers{iI});
            dData = csData{iTestcase};
            dMean(iI, :) = mean(dData);
        end
        dMean = [mean(dMean, 1); dMean];
        if lOnlyMean, dMean = dMean(1, :); end
        bar(dMean');
        hA = gca;
        set(hA, 'XTickLabel', SProject.STestCases(1).csData);
        if ~lOnlyMean, legend(['Overall'; csUsers], 'Orientation', 'horizontal', 'Location', 'southoutside'); end
        set(hF, 'Name', sprintf('Testcase %d', iTestcase));
    end
end


% =========================================================================
% *** FUNCTION fSelectEvalFcns
% ***
% *** Lets the user select the eval functions for evaluation
% ***
% =========================================================================
function sUser = fGetUser(csUsers)

iFIGUREWIDTH = 200;
iFIGUREHEIGHT = 300;
iBUTTONHEIGHT = 24;

iPos = get(0, 'ScreenSize');

% -------------------------------------------------------------------------
% Create figure and GUI elements
hF = figure( ...
    'Position'              , [(iPos(3) - iFIGUREWIDTH)/2, (iPos(4) - iFIGUREHEIGHT)/2, iFIGUREWIDTH, iFIGUREHEIGHT], ...
    'WindowStyle'           , 'modal', ...
    'Name'                  , 'Select User...', ...
    'NumberTitle'           , 'off', ...
    'KeyPressFcn'           , @SelectUserCallback, ...
    'Resize'                , 'off');

hList = uicontrol(hF, ...
    'Style'                 , 'listbox', ...
    'Position'              , [1 2*iBUTTONHEIGHT + 1 iFIGUREWIDTH iFIGUREHEIGHT - 2*iBUTTONHEIGHT], ...
    'String'                , csUsers, ...
    'Min'                   , 0, ...
    'Max'                   , 1, ...
    'Value'                 , 1, ...
    'KeyPressFcn'           , @SelectUserCallback, ...
    'Callback'              , @SelectUserCallback);

hEdit = uicontrol(hF, ...
    'Style'                 , 'edit', ...
    'Position'              , [1 iBUTTONHEIGHT + 1 iFIGUREWIDTH iBUTTONHEIGHT], ...
    'Callback'              , @SelectUserCallback, ...
    'String'                , csUsers{1});

hButOK = uicontrol(hF, ...
    'Style'                 , 'pushbutton', ...
    'Position'              , [1 1 iFIGUREWIDTH/2 iBUTTONHEIGHT], ...
    'Callback'              , @SelectUserCallback, ...
    'String'                , 'OK');

uicontrol(hF, ...
    'Style'                 , 'pushbutton', ...
    'Position'              , [iFIGUREWIDTH/2 + 1 1 iFIGUREWIDTH/2 iBUTTONHEIGHT], ...
    'Callback'              , 'uiresume(gcf);', ...
    'String'                , 'Cancel');

% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Set default action and enable gui interaction
sAction = 'Cancel';
sUser = '';
uiwait(hF);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% uiresume was triggered (in fMouseActionFcn) -> return
if strcmp(sAction, 'OK')
    sUser = get(hEdit, 'String');
end
try %#ok<TRYNC>
    close(hF);
end
% -------------------------------------------------------------------------


    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * *
    % * * NESTED FUNCTION SelectEvalCallback (nested in fSelectEvalFcns)
    % * *
    % * * Determine whether axes are linked
	% * *
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    function SelectUserCallback(hObject, eventdata)
        try
            switch eventdata.Key
                case 'escape', uiresume(hF);
                case 'return'
                    sAction = 'OK';
                    uiresume(hF);
            end
        catch
        end
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        % React on action depending on its source component
        switch(hObject)
            
            case hList
                if strcmp(get(hF, 'SelectionType'), 'open')
                    sAction = 'OK';
                    uiresume(hF);
                else
                    set(hEdit, 'String', csUsers{get(hList, 'Value')});
                end

            case hEdit
                sAction = 'OK';
                uiresume(hF);
                
            case hButOK
                sAction = 'OK';
                uiresume(hF);

            otherwise

        end
        % End of switch statement
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
    end
    % = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    % * * END NESTED FUNCTION SelectEvalCallback
	% = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    
end
% =========================================================================
% *** END FUNCTION fSelectEvalFcns (and its nested functions)
% =========================================================================
