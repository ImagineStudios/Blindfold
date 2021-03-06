function [dImg, SInfo, SCoord] = fReadDICOM(sFolder)

% iMAXSIZE = 256;

if ispc, sS='\'; else sS='/'; end;

if ~nargin, sFolder = cd; end

SFolder = dir(sFolder);
SFiles = SFolder(~[SFolder.isdir]);

% Try to find first readable DICOM file and use as reference
SFirstTag = [];
iInd = 1;
while isempty(SFirstTag) && iInd <= length(SFiles)
    try
        SFirstTag  = dicominfo([sFolder, sS, SFiles(iInd).name]);
    catch
        iInd = iInd + 1;
    end
end
if isempty(SFirstTag)
    return
end

% if(usejava('jvm') && ~feature('ShowFigureWindows'))
%     flagDisp = false;
% else
%     flagDisp = true;
% end

% Try to read the remaining files in the dir
% if(flagDisp), hWait = showWaitbar('Loading DICOM images', 0); end;
iNDicom = 0;
dImg = zeros(SFirstTag.Height, SFirstTag.Width, length(SFiles) - iInd + 1);
for iI = iInd:length(SFiles)
    try        
        % Try to read the Dicom information.
        SThisTag  = dicominfo([sFolder, sS, SFiles(iI).name]);
        [dThisImg, iThisBinHdr]  = fDicomReadFast([sFolder, sS, SFiles(iI).name], SThisTag.Height,  SThisTag.Width);
        dThisImg = double(dThisImg);
%         if ~fTestImageCompatibility(SThisTag, SFirstTag), continue; end
        
        iNDicom = iNDicom + 1;
        if isfield(SThisTag, 'RescaleIntercept')
            dThisImg = dThisImg - SThisTag.RescaleIntercept;
        end
        if isfield(SThisTag, 'RescaleSlope')
            dThisImg = dThisImg.*SThisTag.RescaleSlope;
        end
        dImg(:, :, iNDicom) = dThisImg;
        SInfo(iNDicom).STag = SThisTag;
        SInfo(iNDicom).sFilename = SFiles(iI).name;
        SInfo(iNDicom).iBinHdr = iThisBinHdr;
%         if(flagDisp), hWait = showWaitbar('Loading DICOM images', iI/length(SFiles), hWait); end;
    catch
    end
end
% if(flagDisp), showWaitbar('Loading DICOM images', 'Close', hWait); end;

% Crop Images
dImg = dImg(:, :, 1:iNDicom);

% Sort images according to acquisition time
dTime = zeros(iNDicom, 1);
for iI = 1:length(dTime)
    iHour   = str2double(SInfo(iI).STag.AcquisitionTime(1:2));
    iMin    = str2double(SInfo(iI).STag.AcquisitionTime(3:4));
    iSek    = str2double(SInfo(iI).STag.AcquisitionTime(5:end));
    dTime(iI) = iSek + 60*iMin + 3600*iHour;
end
[temp, iInd] = sort(dTime);
dImg = dImg(:,:,iInd);
SInfo = SInfo(iInd);

% Orientation
dOrient = reshape(SInfo(1).STag.ImageOrientationPatient, [3, 2])';
dPixelSpacing = SInfo(1).STag.PixelSpacing;
dPosition = zeros(length(SInfo), 3);
for iI = 1:length(SInfo)
    dPosition(iI, :) = SInfo(iI).STag.ImagePositionPatient';
end
dOrientIndicator = sum(abs(dOrient));
[dVal, iInd] = min(dOrientIndicator);
switch(iInd)
    case 1
        SCoord.sOrientation = 'Sag';
        SCoord.dLR = dPosition(:, 1);
        SCoord.dAP = (dPosition(1, 2) + dOrient(1, 2).*(0:size(dImg, 2) - 1).*dPixelSpacing(1))';
        SCoord.dFH = (dPosition(1, 3) + dOrient(2, 3).*(0:size(dImg, 1) - 1).*dPixelSpacing(2))';
        
        
    case 2
        SCoord.sOrientation = 'Cor';
        SCoord.dLR = (dPosition(1, 1) + dOrient(1, 1).*(0:size(dImg, 2) - 1).*dPixelSpacing(1))';
        SCoord.dAP = dPosition(:, 2);
        SCoord.dFH = (dPosition(1, 3) + dOrient(2, 3).*(0:size(dImg, 1) - 1).*dPixelSpacing(2))';
        
    case 3
        SCoord.sOrientation = 'Tra';
        SCoord.dLR = (dPosition(1, 1) + dOrient(1, 1).*(0:size(dImg, 2) - 1).*dPixelSpacing(1))';
        SCoord.dAP = (dPosition(1, 2) + dOrient(2, 2).*(0:size(dImg, 1) - 1).*dPixelSpacing(2))';
        SCoord.dFH = dPosition(:, 3);
%         if SCoord.dFH(2) -SCoord.dFH(1) < 1
%             dImg = flipdim(dImg, 3);
%             SCoord.dFH = SCoord.dFH(end:-1:1);
%         end
        [temp, iInd] = sort(SCoord.dFH, 'ascend');
        SCoord.dFH = SCoord.dFH(iInd);
        dImg = dImg(:,:,iInd);
        SInfo = SInfo(iInd);
        
end



fprintf(1, '\nNumber of matching DICOM images in folder : %u\n', iNDicom);
fprintf(1, '          Number of other files in folder : %u\n', length(SFiles) - iNDicom);
fprintf(1, '                           Image Modality : %s\n', SInfo(1).STag.Modality);
fprintf(1, '                        Image Orientation : %s\n', SCoord.sOrientation);
fprintf(1, '                         Image Resolution : %u x %u\n\n', size(dImg, 2), size(dImg, 1));
fprintf(1, '                range              metric FOV           center of FOV\n');
fprintf(1, 'LR     %-3.2f mm .. %-3.2f mm       %-3.2f mm             %-3.2f mm\n', min(SCoord.dLR), max(SCoord.dLR), max(SCoord.dLR) - min(SCoord.dLR), (max(SCoord.dLR) + min(SCoord.dLR))/2);
fprintf(1, 'AP     %-3.2f mm .. %-3.2f mm       %-3.2f mm             %-3.2f mm\n', min(SCoord.dAP), max(SCoord.dAP), max(SCoord.dAP) - min(SCoord.dAP), (max(SCoord.dAP) + min(SCoord.dAP))/2);
fprintf(1, 'FH     %-3.2f mm .. %-3.2f mm       %-3.2f mm             %-3.2f mm\n', min(SCoord.dFH), max(SCoord.dFH), max(SCoord.dFH) - min(SCoord.dFH), (max(SCoord.dFH) + min(SCoord.dFH))/2);




function lMatch = fTestImageCompatibility(STag, SRefTag)

lMatch = false;
% csTagsToCheck = {'FrameOfReferenceUID', 'PixelSpacing', 'ImageOrientationPatient', 'Modality', 'Width', 'Height'};
csTagsToCheck = {'PixelSpacing', 'Modality', 'Width', 'Height'};

for iI = 1:length(csTagsToCheck)
    eval(['rVar = STag.', csTagsToCheck{iI}, ';']);
    eval(['rVarRef = SRefTag.', csTagsToCheck{iI}, ';']);
    if isnumeric(rVar)
        if any(rVar ~= rVarRef)
            fprintf(1, ['*** ', csTagsToCheck{iI}, ' ***\n']);
            return;
        end
    elseif islogical(rVar)
        if any(rVar ~= rVarRef)
            fprintf(1, ['*** ', csTagsToCheck{iI}, ' ***\n']);
            return;
        end
    else
        if ~strcmp(rVar, rVarRef)
            fprintf(1, ['*** ', csTagsToCheck{iI}, ' ***\n']);
            return;
        end
    end
end
lMatch = true;

end


function hWait = showWaitbar(sMessage, dValue, hWait)
    if(exist('multiWaitbar','file'))
        multiWaitbar(sMessage, dValue);
        hWait = 0;
    else
        if(nargin < 3)
            hWait = waitbar(dValue, sMessage);
        else
            if(isnumeric(dValue))
                waitbar(dValue, hWait);
            else % close waitbar
                close(hWait);
            end
        end
    end
end

end