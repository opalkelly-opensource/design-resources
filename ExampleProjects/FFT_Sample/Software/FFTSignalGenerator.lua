-- This is the Lua file for the FFT Signal Generator sample.
-- Copyright (c) 2023, Opal Kelly Incorporated

-- Initialization script
function OnInit(event)

    m_statusString = ""
    m_errorString = ""
    UpdateStatus()

    m_devInfo = OpalKelly.okTDeviceInfo()
    assert(event:GetDevice():GetDeviceInfo(m_devInfo) ==
        OpalKelly.FrontPanel_NoError, "GetDeviceInfo() failed")
    
    dev = event:GetDevice()
    dev:UpdateWireOuts()
    local locked = dev:GetWireOutValue(0x20) & 0x00000001
    local MAX_TRIES = 100
    local tries
    SetStatus("Waiting for clocks to lock...")
    while not locked or tries == MAX_TRIES do
        dev:UpdateWireOuts()
        locked = dev:GetWireOutValue(0x20) & 0x00000001
        tries = tries + 1
    end
    if tries == MAX_TRIES then
        SetError("Clocks did not lock.")
    else
        SetStatus("Clocks locked.")
    end
    
    for i=0,511,1 do -- resets all bins to zero
        dev:WriteRegister(i, 0)
    end
    DebugLog("Frequency Bin BRAM reset.")
end

-- `Reset IFFT` button event
function IfftResetButton(button, event)
    if button:IsPressed() then
        SetError("")
        local panel = okUI:FindPanel("panel1")
        
        dev:SetWireInValue(0x00, 0x00000002)
        dev:UpdateWireIns()
        dev:SetWireInValue(0x00, 0x00000000)
        dev:UpdateWireIns()
        
        local MAX_TRIES = 100
        local tries = 0
        
        dev:UpdateWireOuts()
        m_dacRdy = dev:GetWireOutValue(0x20) & 0x00000002
        while not m_dacRdy and tries < MAX_TRIES do
            dev:UpdateWireOuts()
            m_dacRdy = dev:GetWireOutValue(0x20) & 0x00000002
            tries = tries + 1
            DebugLog("DAC not ready, retrying...")
        end
        
        if tries == MAX_TRIES then
            SetError("SPI commands to DAC did not complete.")
        end
        
        panel:FindDigitDisplay("freq1"):SetValue(0)
        panel:FindDigitDisplay("freq2"):SetValue(0)
        panel:FindDigitDisplay("freq3"):SetValue(0)
        panel:FindDigitDisplay("freq4"):SetValue(0)
        
        panel:FindDigitEntry("bin1"):SetValue(0)
        panel:FindDigitEntry("bin2"):SetValue(0)
        panel:FindDigitEntry("bin3"):SetValue(0)
        panel:FindDigitEntry("bin4"):SetValue(0)
        
        panel:FindToggleCheck("enaBin1"):SetValue(false)
        panel:FindToggleCheck("enaBin2"):SetValue(false)
        panel:FindToggleCheck("enaBin3"):SetValue(false)
        panel:FindToggleCheck("enaBin4"):SetValue(false)
        
        panel:FindDigitEntry("db1"):SetValue(0)
        panel:FindDigitEntry("db2"):SetValue(0)
        panel:FindDigitEntry("db3"):SetValue(0)
        panel:FindDigitEntry("db4"):SetValue(0)
        
        SetStatus("Design Reset.") 
        SetBinsToZero()
    end
    
end

function SetBinsToZero()
    for i=0,254,2 do -- resets the Real Component bins to 0
        dev:WriteRegister(i, 0)
    end
    dev:ActivateTriggerIn(0x40, 1) -- Submits the Bin data to the IFFT
    DebugLog("All bins set to zero.")
end

-- `Send to IFFT` button event
function IfftSend(button, event)

    SetError("")
    local panel = okUI:FindPanel("panel1")
    
    m_bin1Ena = panel:FindToggleCheck("enaBin1"):GetValue()
    m_bin2Ena = panel:FindToggleCheck("enaBin2"):GetValue()
    m_bin3Ena = panel:FindToggleCheck("enaBin3"):GetValue()
    m_bin4Ena = panel:FindToggleCheck("enaBin4"):GetValue()
    
    m_bin1dbfs = 0
    m_bin2dbfs = 0
    m_bin3dbfs = 0
    m_bin4dbfs = 0
    dbfs_sum = 0
    
    m_bin1 = panel:FindDigitEntry("bin1"):GetValue()
    m_bin2 = panel:FindDigitEntry("bin2"):GetValue()
    m_bin3 = panel:FindDigitEntry("bin3"):GetValue()
    m_bin4 = panel:FindDigitEntry("bin4"):GetValue()
    
    panel:FindDigitDisplay("freq1"):SetValue(CalculateFrequency(m_bin1))
    panel:FindDigitDisplay("freq2"):SetValue(CalculateFrequency(m_bin2))
    panel:FindDigitDisplay("freq3"):SetValue(CalculateFrequency(m_bin3))
    panel:FindDigitDisplay("freq4"):SetValue(CalculateFrequency(m_bin4))
    
    if not m_bin1Ena then
        DebugLog("Disabling bin1")
    else
        m_bin1dbfs = DBfsConversion(panel:FindDigitEntry("db1"):GetValue())
        dbfs_sum = dbfs_sum + math.abs(m_bin1dbfs)
        DebugPrintf("Writing To Bin %d with value %d", m_bin1, m_bin1dbfs)
    end
    
    if not m_bin2Ena then
        DebugLog("Disabling bin2")
    else
        m_bin2dbfs = DBfsConversion(panel:FindDigitEntry("db2"):GetValue())
        dbfs_sum = dbfs_sum + math.abs(m_bin2dbfs)
        DebugPrintf("Writing To Bin %d with value %d", m_bin2, m_bin2dbfs)
    end
    
    if not m_bin3Ena then
        DebugLog("Disabling bin3")
    else
        m_bin3dbfs = DBfsConversion(panel:FindDigitEntry("db3"):GetValue())
        dbfs_sum = dbfs_sum + math.abs(m_bin3dbfs)
        DebugPrintf("Writing To Bin %d with value %d", m_bin3, m_bin3dbfs)
    end  
    
    if not m_bin4Ena then
        DebugLog("Disabling bin4")
    else
        m_bin4dbfs = DBfsConversion(panel:FindDigitEntry("db4"):GetValue())
        dbfs_sum = dbfs_sum + math.abs(m_bin4dbfs)
        DebugPrintf("Writing To Bin %d with value %d", m_bin4, m_bin4dbfs)
    end   

    MAX_VALUE = 0x7FFFF
    
    -- Scales magnitudes to prevent clipping
    if panel:FindToggleCheck("autoscale"):GetValue() then
        DebugLogValue("Sum of bin magnitudes: ", dbfs_sum)
        if dbfs_sum > MAX_VALUE then
            DebugLog("Scaling magnitudes...")
            scalar = MAX_VALUE / dbfs_sum
            
            if m_bin1Ena then
                m_bin1dbfs = math.floor(scalar * m_bin1dbfs)
            end
            
            if m_bin2Ena then
                m_bin2dbfs = math.floor(scalar * m_bin2dbfs)
            end
            
            if m_bin3Ena then
                m_bin3dbfs = math.floor(scalar * m_bin3dbfs)
            end
            
            if m_bin4Ena then
                m_bin4dbfs = math.floor(scalar * m_bin4dbfs)
            end
            
        end
    end
    
    SetBinsToZero()
    -- Important: the IFFT bins are implemented as:
    -- bin n real component = n * 2
    -- bin n imaginary component = n * 2 + 1
    if m_bin1Ena then
        dev:WriteRegister(m_bin1 * 2, ConvertToIFFTTwosComp(m_bin1dbfs))
    end
    
    if m_bin2Ena then
        dev:WriteRegister(m_bin2 * 2, ConvertToIFFTTwosComp(m_bin2dbfs))
    end
    
    if m_bin3Ena then
        dev:WriteRegister(m_bin3 * 2, ConvertToIFFTTwosComp(m_bin3dbfs))
    end
    
    if m_bin4Ena then
        dev:WriteRegister(m_bin4 * 2, ConvertToIFFTTwosComp(m_bin4dbfs))
    end
    
    DebugLogValue("Bin 1 magnitude: ", ConvertToIFFTTwosComp(m_bin1dbfs))
    DebugLogValue("Bin 2 magnitude: ", ConvertToIFFTTwosComp(m_bin2dbfs))
    DebugLogValue("Bin 3 magnitude: ", ConvertToIFFTTwosComp(m_bin3dbfs))
    DebugLogValue("Bin 4 magnitude: ", ConvertToIFFTTwosComp(m_bin4dbfs))
    
    SetStatus("Wrote to bins!")
    dev:ActivateTriggerIn(0x40, 1) -- Submits the Bin data to the IFFT
end

-- Converts a dbfs value to an integer the IFFT can use.
-- IFFT uses a 20 bit signed ap_fixed value.
-- We ignore the sign bit here, so:
-- 20 log(2^19)= ~115 dB scale
-- Return scaled integer value based on the dynamic range of 120 dB
function DBfsConversion(dbfs)
    if dbfs == 0 then
        return 0x7FFFF
    else
        return math.floor(10^(dbfs/20) * 0x7FFFF)
    end
end

-- Calculates the frequency given the bin number.
function CalculateFrequency(bin)
    frequency = 125000000 * bin / 256
    DebugLogValue("CalculateFrequency returned: ", frequency)
    return frequency
end

-- Takes a number and returns a signed magnitude 20 bit version of it,
-- as the IFFT core expects a two's complement number.
function ConvertToIFFTTwosComp(val)
    if val < 0 then
        return (math.abs(val) | 0x80000) & 0xFFFFF
    else
        return val & 0x7FFFF
    end
end

-- Diplays frequency for bin 1
function SetFrequencyBox1(de, event)
    local panel = okUI:FindPanel("panel1")
    bin = de:GetValue()
    DebugLogValue("Bin retrieved for bin 1: ", bin)
    panel:FindDigitDisplay("freq1"):SetValue(CalculateFrequency(bin))
end

-- Diplays frequency for bin 2
function SetFrequencyBox2(de, event)
    local panel = okUI:FindPanel("panel1")
    bin = de:GetValue()
    DebugLogValue("Bin retrieved for bin 2: ", bin)
    panel:FindDigitDisplay("freq2"):SetValue(CalculateFrequency(bin))
end

-- Diplays frequency for bin 3
function SetFrequencyBox3(de, event)
    local panel = okUI:FindPanel("panel1")
    bin = de:GetValue()
    DebugLogValue("Bin retrieved for bin 3: ", bin)
    panel:FindDigitDisplay("freq3"):SetValue(CalculateFrequency(bin))
end

-- Diplays frequency for bin 4
function SetFrequencyBox4(de, event)
    local panel = okUI:FindPanel("panel1")
    bin = de:GetValue()
    DebugLogValue("Bin retrieved for bin 4: ", bin)
    panel:FindDigitDisplay("freq4"):SetValue(CalculateFrequency(bin))
end

function SetError(str)
    m_errorString = str
    UpdateStatus()
end

function SetStatus(str)
    m_statusString = str
    UpdateStatus()
end

function UpdateStatus()
    local logControl = okUI:FindPanel("panel1"):FindControl("status")

    local status = "Status: " .. m_statusString
    if m_errorString ~= nil and m_errorString ~= "" then
        status = status .. "\nError: " .. m_errorString
    end

    logControl:SetLabel(status)
end
