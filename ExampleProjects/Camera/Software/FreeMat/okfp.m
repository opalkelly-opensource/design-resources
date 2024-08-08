%import('okFrontPanel.dll', 'okFrontPanel_',       'okFP',       '',      'uint32 hnd');
import('okFrontPanel.dll', 'okFrontPanel_Construct',                      'okFPConstruct',                      'uint32',     '');
import('okFrontPanel.dll', 'okFrontPanel_Destruct',                       'okFPDestruct',                       'void',       'uint32 hnd');
import('okFrontPanel.dll', 'okFrontPanel_WriteI2C',                       'okFPWriteI2C',                       'int32',      'uint32 hnd, int32 addr, int32 length, uint8[length] data');
import('okFrontPanel.dll', 'okFrontPanel_ReadI2C',                        'okFPReadI2C',                        'int32',      'uint32 hnd, int32 addr, int32 length, uint8[length] data');
import('okFrontPanel.dll', 'okFrontPanel_GetHostInterfaceWidth',          'okFPGetHostInterfaceWidth',          'int32',      'uint32 hnd');
import('okFrontPanel.dll', 'okFrontPanel_IsHighSpeed',                    'okFPIsHighSpeed',                    'int32',      'uint32 hnd');
import('okFrontPanel.dll', 'okFrontPanel_GetBoardModel',                  'okFPGetBoardModel',                  'int32',      'uint32 hnd');
import('okFrontPanel.dll', 'okFrontPanel_GetBoardModelString',            'okFPGetBoardModelString',            'void',       'uint32 hnd, int32 m, uint8[64] str');
import('okFrontPanel.dll', 'okFrontPanel_GetDeviceCount',                 'okFPGetDeviceCount',                 'int32',      'uint32 hnd');

import('okFrontPanel.dll', 'okFrontPanel_OpenBySerial',                   'okFPOpenBySerialX',                  'int32',      'uint32 hnd, uint32 x');
import('okFrontPanel.dll', 'okFrontPanel_OpenBySerial',                   'okFPOpenBySerial',                   'int32',      'uint32 hnd, uint8[10] serial');
import('okFrontPanel.dll', 'okFrontPanel_IsOpen',                         'okFPIsOpen',                         'int32',      'uint32 hnd');

import('okFrontPanel.dll', 'okFrontPanel_GetSerialNumber',                'okFPGetSerialNumberX',               'void',       'uint32 hnd, uint8[10] &serial');
%function sn=okFPGetSerialNumber(hnd)
%	sn = '          ';
%	okFPGetSerialNumberX(hnd, sn);
%end

import('okFrontPanel.dll', 'okFrontPanel_ConfigureFPGA',                  'okFPConfigureFPGA',                  'int32',      'uint32 hnd, string bitfile');
import('okFrontPanel.dll', 'okFrontPanel_GetPLL22150Configuration',       'okFPGetPLL22150Configuration',       'int32',      'uint32 hnd, uint32 pll');
import('okFrontPanel.dll', 'okFrontPanel_SetPLL22150Configuration',       'okFPSetPLL22150Configuration',       'int32',      'uint32 hnd, uint32 pll');
import('okFrontPanel.dll', 'okFrontPanel_GetEepromPLL22150Configuration', 'okFPGetEepromPLL22150Configuration', 'int32',      'uint32 hnd, uint32 pll');
import('okFrontPanel.dll', 'okFrontPanel_SetEepromPLL22150Configuration', 'okFPSetEepromPLL22150Configuration', 'int32',      'uint32 hnd, uint32 pll');
import('okFrontPanel.dll', 'okFrontPanel_GetPLL22393Configuration',       'okFPGetPLL22393Configuration',       'int32',      'uint32 hnd, uint32 pll');
import('okFrontPanel.dll', 'okFrontPanel_SetPLL22393Configuration',       'okFPSetPLL22393Configuration',       'int32',      'uint32 hnd, uint32 pll');
import('okFrontPanel.dll', 'okFrontPanel_GetEepromPLL22393Configuration', 'okFPGetEepromPLL22393Configuration', 'int32',      'uint32 hnd, uint32 pll');
import('okFrontPanel.dll', 'okFrontPanel_SetEepromPLL22393Configuration', 'okFPSetEepromPLL22393Configuration', 'int32',      'uint32 hnd, uint32 pll');
import('okFrontPanel.dll', 'okFrontPanel_LoadDefaultPLLConfiguration',    'okFPLoadDefaultPLLConfiguration',    'int32',      'uint32 hnd');
import('okFrontPanel.dll', 'okFrontPanel_IsFrontPanelEnabled',            'okFPIsFrontPanelEnabled',            'int32',      'uint32 hnd');
import('okFrontPanel.dll', 'okFrontPanel_IsFrontPanel3Supported',         'okFPIsFrontPanel3Supported',         'int32',      'uint32 hnd');
import('okFrontPanel.dll', 'okFrontPanel_UpdateWireIns',                  'okFPUpdateWireIns',                  'void',       'uint32 hnd');
import('okFrontPanel.dll', 'okFrontPanel_SetWireInValue',                 'okFPSetWireInValue',                 'int32',      'uint32 hnd, int32 ep, uint32 val, uint32 mask');
import('okFrontPanel.dll', 'okFrontPanel_UpdateWireOuts',                 'okFPUpdateWireOuts',                 'void',       'uint32 hnd');
import('okFrontPanel.dll', 'okFrontPanel_GetWireOutValue',                'okFPGetWireOutValue',                'uint32',     'uint32 hnd, int32 ep');
import('okFrontPanel.dll', 'okFrontPanel_ActivateTriggerIn',              'okFPActivateTriggerIn',              'int32',      'uint32 hnd, int32 ep, int32 bit');
import('okFrontPanel.dll', 'okFrontPanel_UpdateTriggerOuts',              'okFPUpdateTriggerOuts',              'void',       'uint32 hnd');
import('okFrontPanel.dll', 'okFrontPanel_IsTriggered',                    'okFPIsTriggered',                    'int32',      'uint32 hnd, int32 ep, uint32 mask');
import('okFrontPanel.dll', 'okFrontPanel_GetLastTransferLength',          'okFPGetLastTransferLength',          'int32',      'uint32 hnd');
import('okFrontPanel.dll', 'okFrontPanel_WriteToPipeIn',                  'okFPWriteToPipeIn',                  'int32',      'uint32 hnd, int32 ep, int32 length, uint8[length] data');
import('okFrontPanel.dll', 'okFrontPanel_ReadFromPipeOut',                'okFPReadFromPipeOut',                'int32',      'uint32 hnd, int32 ep, int32 length, uint8[length] &data');
import('okFrontPanel.dll', 'okFrontPanel_WriteToBlockPipeIn',             'okFPWriteToBlockPipeIn',             'int32',      'uint32 hnd, int32 ep, int32 blocksize, int32 length, uint8[length] data');
import('okFrontPanel.dll', 'okFrontPanel_ReadFromBlockPipeOut',           'okFPReadFromBlockPipeOut',           'int32',      'uint32 hnd, int32 ep, int32 blocksize, int32 length, uint8[length] &data');
