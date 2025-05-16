Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Base64 Decoder"
        Height="360" Width="520"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#222"
        WindowStyle="None"
        AllowsTransparency="False">
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#EEE"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#333"/>
            <Setter Property="Foreground" Value="#EEE"/>
            <Setter Property="BorderBrush" Value="#555"/>
            <Setter Property="CaretBrush" Value="#EEE"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="OverridesDefaultStyle" Value="True"/>
            <Setter Property="Background" Value="#444"/>
            <Setter Property="Foreground" Value="#EEE"/>
            <Setter Property="BorderBrush" Value="#666"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="4,2"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="3">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#223366"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter Property="Background" Value="#112244"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Background" Value="#333"/>
                    <Setter Property="Foreground" Value="#888"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="Image">
            <Setter Property="Margin" Value="0,8,0,0"/>
        </Style>
    </Window.Resources>
    <Border Background="#222" BorderBrush="#444" BorderThickness="1" CornerRadius="6">
        <Grid Margin="0">
            <Grid.RowDefinitions>
                <RowDefinition Height="36"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <!-- Custom Title Bar -->
            <Grid Grid.Row="0" Background="#222" Height="36">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="36"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="24"/>
                </Grid.ColumnDefinitions>
                <!-- Left spacer (empty, for symmetry) -->
                <Border Grid.Column="0" Background="#222"/>
                <!-- Centered title -->
                <TextBlock Grid.Column="1"
                           Text="Base64 Decoder"
                           Foreground="#EEE"
                           FontWeight="Normal"
                           FontSize="15"
                           VerticalAlignment="Center"
                           HorizontalAlignment="Center"
                           TextAlignment="Center"/>
                <!-- Close button -->
                <Button Grid.Column="2"
                        Content="X"
                        Width="24"
                        Height="24"
                        Background="#222"
                        Foreground="#EEE"
                        BorderBrush="#444"
                        FontWeight="Bold"
                        FontSize="12"
                        HorizontalAlignment="Right"
                        VerticalAlignment="Top"
                        Margin="0"
                        Cursor="Hand"
                        Name="CloseBtn"/>
            </Grid>
            <!-- Main Content -->
            <Grid Grid.Row="1" Margin="18,0,18,18">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                
                <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,12">
                    <TextBlock Text="Base64:" FontWeight="Bold" VerticalAlignment="Top" Margin="0,8,10,0"/>
                    <TextBox Name="Base64Box" Width="400" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" Height="70" TextWrapping="Wrap"/>
                </StackPanel>
                <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,12">
                    <TextBlock Text="Output File:" VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <TextBox Name="OutputBox" Width="270" Margin="0,0,8,0"/>
                    <Button Name="BrowseBtn" Content="Browse..." Width="75"/>
                </StackPanel>
                <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,12">
                    <Button Name="DecodeBtn" Content="Decode and Save" Width="140" Height="32" Margin="0,0,16,0"/>
                    <Button Name="ViewBtn" Content="View Without Saving" Width="170" Height="32"/>
                </StackPanel>
                <Image Name="PreviewImage" Grid.Row="3" Height="80" Stretch="Uniform" Visibility="Collapsed"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$Base64Box = $window.FindName("Base64Box")
$OutputBox = $window.FindName("OutputBox")
$BrowseBtn = $window.FindName("BrowseBtn")
$DecodeBtn = $window.FindName("DecodeBtn")
$ViewBtn = $window.FindName("ViewBtn")
$PreviewImage = $window.FindName("PreviewImage")
$CloseBtn = $window.FindName("CloseBtn")

$CloseBtn.Add_Click({
    $window.Close()
})

# Add window dragging
$TitleBar = $window.Content.FindName("PART_TitleBar")
if (-not $TitleBar) {
    $TitleBar = $window.Content.Child.Children[0]
}
$TitleBar.Add_MouseLeftButtonDown({
    if ($_.OriginalSource -ne $CloseBtn) {
        $window.DragMove()
    }
})

$BrowseBtn.Add_Click({
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = "PDF Files (*.pdf)|*.pdf|Image Files (*.jpg;*.png)|*.jpg;*.png|All Files (*.*)|*.*"
    if ($dlg.ShowDialog()) {
        $OutputBox.Text = $dlg.FileName
    }
})

$DecodeBtn.Add_Click({
    $base64 = $Base64Box.Text.Trim()
    $output = $OutputBox.Text.Trim()
    if (-not $base64) {
        [System.Windows.MessageBox]::Show("Please enter a Base64 string.", "Error", "OK", "Error")
        return
    }
    if (-not $output) {
        [System.Windows.MessageBox]::Show("Please specify an output file.", "Error", "OK", "Error")
        return
    }
    if ($base64 -match "^data:.*;base64,") {
        $base64 = $base64 -replace "^data:.*;base64,", ""
    }
    try {
        [IO.File]::WriteAllBytes($output, [Convert]::FromBase64String($base64))
        [System.Windows.MessageBox]::Show("File saved to $output", "Success", "OK", "Information")
    } catch {
        [System.Windows.MessageBox]::Show("Failed to decode or save file.`n$($_.Exception.Message)", "Error", "OK", "Error")
    }
})

$ViewBtn.Add_Click({
    $base64 = $Base64Box.Text.Trim()
    if (-not $base64) {
        [System.Windows.MessageBox]::Show("Please enter a Base64 string.", "Error", "OK", "Error")
        return
    }
    # Remove data URI prefix if present
    if ($base64 -match "^data:.*;base64,") {
        $base64 = $base64 -replace "^data:.*;base64,", ""
    }
    try {
        $bytes = [Convert]::FromBase64String($base64)
        $stream = New-Object System.IO.MemoryStream(,$bytes)
        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmap.BeginInit()
        $bitmap.StreamSource = $stream
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.EndInit()
        $bitmap.Freeze()
        $PreviewImage.Source = $bitmap
        $PreviewImage.Visibility = "Visible"
    } catch {
        $PreviewImage.Visibility = "Collapsed"
        try {
            $tmp = [System.IO.Path]::GetTempFileName()
            # Try to guess extension from header
            if ($base64.Substring(0,5) -eq "JVBER") {
                $tmp = [System.IO.Path]::ChangeExtension($tmp, ".pdf")
            } elseif ($base64.Substring(0,8) -eq "/9j/4AAQ") {
                $tmp = [System.IO.Path]::ChangeExtension($tmp, ".jpg")
            } elseif ($base64.Substring(0,8) -eq "iVBORw0K") {
                $tmp = [System.IO.Path]::ChangeExtension($tmp, ".png")
            }
            [IO.File]::WriteAllBytes($tmp, $bytes)
            Start-Process $tmp
        } catch {
            [System.Windows.MessageBox]::Show("Cannot preview or open this file. It may not be a supported image or document.`n$($_.Exception.Message)", "Error", "OK", "Error")
        }
    }
})

$window.ShowDialog() | Out-Null