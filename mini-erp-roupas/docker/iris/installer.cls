Class App.Installer
{
XData Install [ XMLNamespace = "http://www.intersystems.com/installer" ]
{
<Manifest>
  <Default Production=""/>
  <Namespace Name="USER" Create="no">
    <Import File="/opt/app/src" Recurse="1" Flags="ck"/>
  </Namespace>
</Manifest>
}

ClassMethod setup(ByRef pParams) As %Status
{
    Quit ##class(%Installer.Manifest).%Process(%XML.XData.Template("Install"), .pParams)
}
}
