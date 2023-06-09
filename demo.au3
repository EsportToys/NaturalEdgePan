#OnAutoItStartRegister SetProcessDPIAware
#NoTrayIcon

Init()
Main()

Func Init()
     Global Const $user32 = DllOpen("user32.dll")
     Global $g_hCursor = MakeCursor(639,639)
     OnAutoItExitRegister ( Cleanup )
     Global $imgW = 1600
     Global $imgH = 1342
     Global $scnW = 321
     Global $scnH = 241
     Global $panX = 0
     Global $panY = 0
     Global $xImg = 0 - 80
     Global $yImg = $scnH-$imgH + 30
     Global $xCha = 163
     Global $yCha = 1342 - 80
     Global $rCha = 8
     Global $xTar = $xCha
     Global $yTar = $yCha

     Local $hWnd = GUICreate("Camera Control Concept",$scnW,$scnH,Round((@DesktopWidth-$scnW)/2),Round((@DesktopHeight-$scnH)/2),0x80000000,0x02000000)
     Global $hImg = GUICtrlCreatePic("map.jpg",$xImg,$yImg,$imgW,$imgH)
     GUISetBkColor(0x000000,$hWnd)

     Local $dim = WinGetPos($hWnd)
     MouseMove(Int($dim[0]+$dim[2]/2),Int($dim[1]+$dim[3]/2),0)
     GUISetState(@SW_SHOW,GUICreate("Instructions",150,$dim[3],$dim[0]-200,$dim[1],0x80000000,0x02080080,$hWnd))
     GUICtrlSetFont( _
       GUICtrlCreateLabel( _
       "MB2 = Move"            & @CRLF & _
       "F = Teleport"          & @CRLF & _
       "B = Recall"            & @CRLF & _
       "Esc = Quit"            & @CRLF & _
       @CRLF & _
       "Default = Edge-Pan"    & @CRLF & _
       "Hold MB3 = Auto-Pan"   & @CRLF & _
       "Hold MB1 = Grab-Pan"   & @CRLF & _
       "Hold Space = Lock Cam" & @CRLF & _
       "Hold Shift = Map-Pan"  & @CRLF & _
       "CapsLk = Lock Map-Pan" , 0 , 0 ,150,$dim[3] ) , 8.5*96/GetDpiForWindow($hWnd) )
     
     Global $hOverlay = GUICreate("Overlay",$dim[2],$dim[3],$dim[0],$dim[1],0x80000000,0x02080080,$hWnd)
     Global $hCha = GUICtrlCreateButton("",Round($xImg)+Round($xCha)-$rCha,Round($yImg)+Round($yCha)-$rCha,2*$rCha+1,2*$rCha+1)
     GUICtrlSetBkColor($hCha, 0xff00ff)
     Global $hDrg = GUICtrlCreateButton("",-6,-6,2*3+1,2*3+1)
     GUICtrlSetBkColor($hDrg, 0xffffff)
     GUISetBkColor(0x0000F4,$hOverlay)
     DllCall("user32.dll", "bool", "SetLayeredWindowAttributes", "hwnd", $hOverlay, "INT", 0x00F40000, "byte", 255, "dword", 0x03)

     Local $spd = [ DllStructCreate("uint s") , DllStructCreate("uint s") ]
     Local $acc = [ DllStructCreate("uint t1;uint t2;uint a") , DllStructCreate("uint t1;uint t2;uint a") ]
     DllCall("user32.dll", "none", "SystemParametersInfo", "uint",  0x0070, "uint",  0, "ptr" ,  DllStructGetPtr($spd[0]), "uint",  0)
     DllCall("user32.dll", "none", "SystemParametersInfo", "uint",  0x0003, "uint",  0, "ptr" ,  DllStructGetPtr($acc[0]), "uint",  0)
     $acc[1].t1=0
     $acc[1].t2=0
     $acc[1].a=0
     $spd[1].s=5
     resetSens($spd[0].s,$acc[0])
     setSens  ($spd[1].s,$acc[1])
     Local $struct = DllStructCreate('struct;ushort UsagePage;ushort Usage;dword Flags;hwnd Target;endstruct')
     With  $struct
           .Target = $hWnd
           .Flags = 0x00000100
           .UsagePage = 0x01
           .Usage = 0x02
           DllCall('user32.dll', 'bool', 'RegisterRawInputDevices', 'struct*', $struct, 'uint', 1, 'uint', DllStructGetSize($struct))
           .UsagePage = 0x01
           .Usage = 0x06
           DllCall('user32.dll', 'bool', 'RegisterRawInputDevices', 'struct*', $struct, 'uint', 1, 'uint', DllStructGetSize($struct))
     EndWith

     Global $sens = CurrentSens($hWnd)
     OnAutoItExitRegister(resetSens)
     GUISetState(@SW_DISABLE,$hWnd)
     GUISetState(@SW_SHOW,$hWnd)
     GUISetState(@SW_DISABLE,$hOverlay)
     GUISetState(@SW_SHOW,$hOverlay)
     GUIRegisterMsg(0x0020,WM_SETCURSOR)
     setCustomCursor()
     GUIRegisterMsg(0x00FF,WM_INPUT)
EndFunc

Func Main()
     Local $time=TimerInit(), $lastImgX, $lastImgY, $lastChaX, $lastChaY, $imgX, $imgY, $chaX, $chaY, $dt, $dx, $dy, $dr, $ds
     do
        $dt = TimerDiff($time)
        If $dt<16 Then ContinueLoop
        $time = TimerInit()
        $dx = $xTar - $xCha
        $dy = $yTar - $yCha
        $dr = sqrt($dx*$dx + $dy*$dy)
        $ds = ( $dr=0 ? 0 : _Clamp(0,$dt*0.1/$dr,1) )
        $xCha += $dx*$ds
        $yCha += $dy*$ds
        If BitAnd(GetAsyncKeyState(0x0020,$user32),0x8000) Then
           $xImg = _Clamp($scnW-$imgW,$scnW/2 - $xCha,0)
           $yImg = _Clamp($scnH-$imgH,$scnH/2 - $yCha,0)
        EndIf
        $imgX = Int($xImg)
        $imgY = Int($yImg)
        $chaX = Int($xImg+$xCha)-$rCha
        $chaY = Int($yImg+$yCha)-$rCha
        If $chaX<>$lastChaX or $chaY<>$lastChaY Then
           GUICtrlSetPos($hCha,$chaX,$chaY)
           $lastChaX=$chaX
           $lastChaY=$chaY
        EndIf
        If $imgX<>$lastImgX or $imgY<>$lastImgY Then
           GUICtrlSetPos($hImg,$imgX,$imgY)
           $lastImgX=$imgX
           $lastImgY=$imgY
        EndIf
     until 0
EndFunc

Func Cleanup()
     DllCall($user32,'bool','DestroyCursor','handle',$g_hCursor)
     DllClose($user32)
EndFunc

Func SetProcessDPIAware()
     GUICreate("")
     DllCall("user32.dll", "bool", "SetProcessDPIAware")
     GUIDelete()
EndFunc

Func GetDpiForWindow($hWnd)
     Local $dpi = DllCall("user32.dll", "uint", "GetDpiForWindow", "handle", $hWnd)
     Return $dpi[0]
EndFunc

Func GetAsyncKeyState($key,$dll="user32.dll")
     Local $state = DllCall($dll, "short", "GetAsyncKeyState", "int", $key)
     Return $state[0]
EndFunc

Func CurrentSens($hWnd)
     Local $spd = DllStructCreate("uint s"), $acc = DllStructCreate("uint;uint;uint a")
     DllCall("user32.dll", "none", "SystemParametersInfo", "uint",  0x0070, "uint",  0, "ptr" ,  DllStructGetPtr($spd), "uint",  0)
     DllCall("user32.dll", "none", "SystemParametersInfo", "uint",  0x0003, "uint",  0, "ptr" ,  DllStructGetPtr($acc), "uint",  0)
     Return CalcSens($spd.s,$acc.a,GetDpiForWindow($hWnd))
EndFunc

Func CalcSens($spd,$acc,$dpi)
     Return ( $acc ? $spd/10 : ( $spd<4 ? BitShift(1,-$spd)/64 : 1 + ($spd-10)/BitShift(8,Int($spd/10.5)) ) ) * $dpi/96
EndFunc

Func resetSens($speed=Null,$accel=Null)
     Local Static $spd = $speed, $acc = $accel
     DllCall("user32.dll", "none", "SystemParametersInfo", "uint",  0x0071, "uint",  0, "uint",  $spd, "uint",  0)
     DllCall("user32.dll", "none", "SystemParametersInfo", "uint",  0x0004, "uint",  0, "ptr" ,  DllStructGetPtr($acc), "uint",  0)
EndFunc

Func setSens($speed=Null,$accel=Null)
     Local Static $spd = $speed, $acc = $accel
     DllCall("user32.dll", "none", "SystemParametersInfo", "uint",  0x0071, "uint",  0, "uint",  $spd, "uint",  0)
     DllCall("user32.dll", "none", "SystemParametersInfo", "uint",  0x0004, "uint",  0, "ptr" ,  DllStructGetPtr($acc), "uint",  0)
EndFunc

Func setCustomCursor($path=Null)
#cs
     Local Static $arr = DllCall( "User32.dll", "handle","LoadImage", "handle", Null, "str", $path, "uint", 2, "int", 0, "int", 0, "uint", 0x00000010  )
     DllCall( "user32.dll" , "handle","SetCursor" , "handle", $arr[0] )
#ce
     DllCall( "user32.dll" , "handle","SetCursor" , "handle", $g_hCursor )
EndFunc

Func WM_INPUT($hWnd,$Msg,$wParam,$lParam)
     Local Static $tagHeader  ='struct;dword Type;dword Size;handle hDevice;wparam wParam;endstruct;'
     Local Static $tagMouse   = $tagHeader & 'ushort flag;ushort Alignment;ushort bflg;short bdta;ulong rbtn;long dx;long dy;ulong xtra;'
     Local Static $tagKeybd   = $tagHeader & 'ushort MakeCode;ushort Flags;ushort Reserved;ushort VKey;uint Message;ulong ExtraInformation;'
     Local Static $sizeHeader = DllStructGetSize(DllStructCreate($tagHeader))
     Local Static $sizeMouse  = DllStructGetSize(DllStructCreate($tagMouse))
     Local Static $sizeKeybd  = DllStructGetSize(DllStructCreate($tagKeybd))
     Local $arr = DllCall($user32, 'uint', 'GetRawInputData', 'handle', $lParam, 'uint', 0x10000005, 'struct*', DllStructCreate($tagHeader), 'uint*', $sizeHeader, 'uint', $sizeHeader)
     Local $pos = DllCall($user32, 'dword', 'GetMessagePos')
     Local $struct = DllStructCreate($arr[3].Type=1?$tagKeybd:$tagMouse), $sizeStruct = ($arr[3].Type=1?$sizeKeybd:$sizeMouse)
     DllCall( $user32, 'uint','GetRawInputData', 'handle', $lParam, 'uint', 0x10000003, 'struct*', $struct, 'uint*', $sizeStruct, 'uint', $sizeHeader )
     ProcessInput($struct,$pos[0],$hWnd)
     If $wParam then Return 0
EndFunc

Func WM_SETCURSOR($hWnd,$Msg,$wParam,$lParam)
     Return True
EndFunc

Func ProcessInput($struct,$pos,$hWnd)
     Local Static $lastFocus=1, $drag = False, $shift = False, $flash = False
     Local $focusChange = $lastFocus-$struct.wParam
     $lastFocus=$struct.wParam
     If Not $struct.wParam Then
        If $focusChange Then 
           Clip($hWnd)
           setSens()
           setCustomCursor()
        EndIf
        Local $_ = $struct
        Local $x=BitAnd($pos, 0xFFFF), $y=BitShift($pos, 16)
        If $_.Type = 0 Then
           If BitAnd(1,$_.bflg) Then $drag = True
           If BitAnd(2,$_.bflg) Then $drag = False
           If BitAnd(4,$_.bflg) Then Move($x,$y,$hWnd)
;           If BitAnd(8,$_.bflg) Then Clip($hWnd)
           If BitAnd(16,$_.bflg) Then
              $panX = $x
              $panY = $y
              AdlibRegister ( "Pan" , 16 )
              Local $dim = WinGetPos($hWnd)
              GUICtrlSetPos($hDrg,$x-3-$dim[0],$y-3-$dim[1])
           EndIf
           If BitAnd(32,$_.bflg) Then
              AdlibUnRegister ( "Pan" )
              GUICtrlSetPos($hDrg,-7,-7)
           EndIf
           If BitAnd(1,$_.flag) Then
              ; absolute movement
           ElseIf $_.dx or $_.dy Then
              If isFixed() Then
                 $xImg = _Clamp($scnW-$imgW,$xImg-$_.dx*$sens,0)
                 $yImg = _Clamp($scnH-$imgH,$yImg-$_.dy*$sens,0)
              ElseIf $drag Then
                 $xImg = _Clamp($scnW-$imgW,$xImg+$_.dx*$sens,0)
                 $yImg = _Clamp($scnH-$imgH,$yImg+$_.dy*$sens,0)
              Else
                 Local $clip = GetClipCursor()
                 If $x+$_.dx<$clip.Left or $x+$_.dx>$clip.Right-1 Then 
                    $xImg = _Clamp($scnW-$imgW,$xImg-$_.dx*$sens,0)
                 EndIf
                 If $y+$_.dy<$clip.Top or $y+$_.dy>$clip.Bottom-1 Then
                    $yImg = _Clamp($scnH-$imgH,$yImg-$_.dy*$sens,0)
                 EndIf
              EndIf
           EndIf
        ElseIf $_.Type = 1 Then
           Switch $_.VKey 
             Case 0x1b ; esc
                  exit
             Case 0x46 ; f
                  If $_.Message = 0x100 Then
                     If Not $flash Then 
                        $flash = True
                        Tele($x,$y,$hWnd)
                     EndIf
                  Else
                     $flash = False
                  EndIf
             Case 0x10 ; shift
                  If $_.Message = 0x100 Then
                     If Not $shift Then 
                        $shift = True
                        Fix()
                     EndIf
                  Else
                     $shift = False
                     Clip($hWnd)
                  EndIf
             Case 0x20 ; space
             Case 0x14 ; capslk
                  If $_.Message = 0x101 Then
                     If isFixed() Then
                        Clip($hWnd)
                     Else
                        Trap($hWnd)
                     EndIf
                  EndIf
             Case 0x42 ; b
                  If $_.Message = 0x101 Then
                     $xTar = 163
                     $yTar = 1342 - 80
                     $xCha = $xTar
                     $yCha = $yTar
                     $xImg = 0 - 80
                     $yImg = $scnH-$imgH + 30
                  EndIf
           EndSwitch
        EndIf
     ElseIf $focusChange Then 
        resetSens()
        AdlibUnRegister ( "Pan" )
        GUICtrlSetPos($hDrg,-7,-7)
     EndIf
EndFunc

Func Trap($hWnd)
     Local $dim = WinGetPos($hWnd)
     ClipCursor(Int($dim[0]+$dim[2]/2),Int($dim[1]+$dim[3]/2),Int($dim[0]+$dim[2]/2)+1,Int($dim[1]+$dim[3]/2)+1)
EndFunc

Func Clip($hWnd)
     Local $dim = WinGetPos($hWnd)
     ClipCursor($dim[0],$dim[1],$dim[0]+$dim[2],$dim[1]+$dim[3])
EndFunc

Func Fix()
     Local $pos = MouseGetPos()
     ClipCursor($pos[0],$pos[1],$pos[0]+1,$pos[1]+1)
EndFunc

Func Pan()
     Local $pos = MouseGetPos()
     Local $dx = round(($pos[0]-$panX)/4)
     Local $dy = round(($pos[1]-$panY)/4)
     $xImg = _Clamp($scnW-$imgW,$xImg-$dx,0)
     $yImg = _Clamp($scnH-$imgH,$yImg-$dy,0)
EndFunc

Func Move($x,$y,$hWnd)
     Local $dim = WinGetPos($hWnd)
     $xTar = $x-$dim[0]-$xImg
     $yTar = $y-$dim[1]-$yImg
EndFunc

Func Tele($x,$y,$hWnd)
     Local $dim = WinGetPos($hWnd)
     $xTar = $x-$dim[0]-$xImg
     $yTar = $y-$dim[1]-$yImg
     $xCha = $x-$dim[0]-$xImg
     $yCha = $y-$dim[1]-$yImg
EndFunc

Func ClipCursor($L=0,$T=0,$R=0,$B=0)
     If @NumParams=4 Then
        Local $struct = DllStructCreate("struct;long Left;long Top;long Right;long Bottom;endstruct")
        $struct.Left   = $L
        $struct.Top    = $T
        $struct.Right  = $R
        $struct.Bottom = $B
        DllCall( "user32.dll", "bool", "ClipCursor", "struct*", $struct )
     Else
        DllCall( "user32.dll", "bool", "ClipCursor", "struct*", Null )
     EndIf
EndFunc

Func MakeCursor($hor,$ver)
     Local $widthInBytes = 2*ceiling(ceiling($hor/2)/8)
     Local $totBytes = $widthInBytes*$ver
     Local $curAND = DllStructCreate("byte[" & $totBytes & "]")
     Local $curXOR = DllStructCreate("byte[" & $totBytes & "]")
     Local $and , $xor

     Local $xByteCenter1Based = ceiling((int($hor/2)+1)/8)
     Local $ctrShift = int($hor/2) - 8*($xByteCenter1Based-1)
     Local $edgShift = 8*ceiling($hor/8)-$hor
     For $i = 1 to $ver
         For $j = 1 to ceiling($hor/8)
             $and = 0xff
             $xor = 0x00
             If $j = $xByteCenter1Based Then
                $xor = BitShift( 0x80 ,$ctrShift)
;                $and = 255-BitShift( 0x80 ,$ctrShift)
             EndIf
             If $i = int($ver/2)+1 Then
                $xor = ( $j=ceiling($hor/8) ? Round(exp($edgShift*log(2))*Int(255*exp(-$edgShift*log(2)))) : 0xff )
;                $and = ( $j=ceiling($hor/8) ? 255-Round(exp($edgShift*log(2))*Int(255*exp(-$edgShift*log(2)))) : 0x00 )
             EndIf
             DllStructSetData( $curAND , 1 , $and , $j+$widthInBytes*($i-1) )
             DllStructSetData( $curXOR , 1 , $xor , $j+$widthInBytes*($i-1) )
        Next
        If Mod(ceiling($hor/8),2)<>0 Then
           DllStructSetData( $curAND , 1 , 0xff , $i*$widthInBytes )
           DllStructSetData( $curXOR , 1 , 0x00 , $i*$widthInBytes )
        EndIf
     Next
     Local $andMaskPtr = DllStructGetPtr($curAnd), $xorMaskPtr = DllStructGetPtr($curXor)
     Return CreateCursor(Null, int($hor/2), int($ver/2), 8*$widthInBytes, $ver, $andMaskPtr, $xorMaskPtr)
EndFunc

Func CreateCursor($hInst, $xHotSpot, $yHotSpot, $nWidth, $nHeight, $pvANDPlane, $pvXORPlane)
     Return DllCall( "user32.dll", "handle", "CreateCursor", _
                                   "handle", $hInst, _
                                      "int", $xHotSpot, _
                                      "int", $yHotSpot, _
                                      "int", $nWidth, _
                                      "int", $nHeight, _
                                      "ptr", $pvANDPlane, _
                                      "ptr", $pvXORPlane )[0]
EndFunc

Func GetClipCursor()
     Local $struct = DllStructCreate("struct;long Left;long Top;long Right;long Bottom;endstruct")
     DllCall( "user32.dll", "bool", "GetClipCursor", "struct*", $struct )
     Return $struct
EndFunc

Func isNotClipped()
     Local $struct = GetClipCursor()
     Return $struct.Left=0 and $struct.Top=0 and $struct.Right=@DesktopWidth and $struct.Bottom=@DesktopHeight
EndFunc

Func isFixed()
     Local $struct = GetClipCursor()
     Return ($struct.Right-$struct.Left)<2 and ($struct.Bottom-$struct.Top)<2
EndFunc

Func _Clamp($min, $val, $max)
     Return $val<$min?$min:($val>$max?$max:$val)
EndFunc
