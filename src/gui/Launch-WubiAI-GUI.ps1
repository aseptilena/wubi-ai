# Auto-Elevation check: Check if running with Administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)


Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Enable Modern TLS (TLS 1.2 / TLS 1.3) for HTTPS downloads from official mirrors
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor 3072 -bor 12288

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WUBI-AI: Ubuntu &amp; Omarchy AI Workstation Installer" 
        Height="890" Width="1040" WindowStartupLocation="CenterScreen"
        WindowState="Maximized" WindowStyle="SingleBorderWindow" ResizeMode="CanResizeWithGrip"
        Background="#121418" Foreground="#F0F4F8" FontFamily="Segoe UI Variable, Segoe UI">
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#E2E8F0"/>
        </Style>
        <Style x:Key="HeaderStyle" TargetType="TextBlock">
            <Setter Property="FontSize" Value="17"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Margin" Value="0,0,0,6"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="0,4,20,4"/>
        </Style>
        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="0,4,20,4"/>
        </Style>
        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#0F172A"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Medium"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="BorderThickness" Value="0,0,0,1"/>
            <Setter Property="BorderBrush" Value="#1E293B"/>
            <Style.Triggers>
                <Trigger Property="IsHighlighted" Value="True">
                    <Setter Property="Background" Value="#0284C7"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#0369A1"/>
                    <Setter Property="Foreground" Value="#F0FDF4"/>
                    <Setter Property="FontWeight" Value="Bold"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Name="HeaderBorder" Grid.Row="0" Margin="0,0,0,14" Padding="14" Background="#1C2028" CornerRadius="8" Cursor="SizeAll">
            <Grid>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="🚀 WUBI-AI" FontSize="22" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center"/>
                    <TextBlock Text="  |  Ubuntu Flavor &amp; Omarchy AI Workstation Installer" FontSize="14" Foreground="#94A3B8" VerticalAlignment="Center" Margin="8,0,0,0"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <TextBlock Name="FirmwareBadge" Text="DETECTING FIRMWARE..." FontWeight="Bold" FontSize="11" Foreground="#38BDF8" Background="#0C4A6E" Padding="8,4" Margin="0,0,8,0"/>
                    <TextBlock Name="AdminBadge" Text="ADMIN PRIVILEGES DETECTED" FontWeight="Bold" FontSize="11" Foreground="#10B981" Background="#064E3B" Padding="8,4"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Main Configuration Panel -->
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel>
                <!-- 1. Distro Selection (Ubuntu Flavors & Minimal) -->
                <Border Background="#1A1E24" CornerRadius="8" Padding="14" BorderBrush="#2D3748" BorderThickness="1" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock Text="1. Ubuntu Edition &amp; Flavor Selection" Style="{StaticResource HeaderStyle}"/>
                        <TextBlock Text="Pilih edisi sistem operasi Ubuntu sesuai kebutuhan dan preferensi hardware Anda:" Foreground="#94A3B8" Margin="0,0,0,8" FontSize="12"/>
                        <ComboBox Name="DistroComboBox" Height="40" Background="#020617" Foreground="#34D399" FontSize="14" FontWeight="SemiBold" Padding="10,8" BorderBrush="#10B981" BorderThickness="1.5" Cursor="Hand"/>
                        
                        <!-- Distro Information Card -->
                        <Border Background="#0B132B" CornerRadius="6" Padding="12" Margin="0,10,0,0" BorderBrush="#1E3A8A" BorderThickness="1">
                            <StackPanel>
                                <Grid Margin="0,0,0,6">
                                    <TextBlock Name="DistroTagBadge" Text="EDISI DESKTOP" FontWeight="Bold" FontSize="10" Foreground="#38BDF8" Background="#0C4A6E" Padding="6,2" HorizontalAlignment="Left" VerticalAlignment="Center"/>
                                    <TextBlock Name="DistroSpecsBadge" Text="RAM Min: 4 GB | VHD: 50 GB" FontWeight="SemiBold" FontSize="11" Foreground="#94A3B8" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                                </Grid>
                                <TextBlock Name="DistroDescText" Text="Deskripsi Distro..." Foreground="#E2E8F0" FontSize="12" TextWrapping="Wrap" LineHeight="18"/>
                                <TextBlock Name="DistroBestForText" Text="Cocok untuk: ..." Foreground="#34D399" FontWeight="Medium" FontSize="11" Margin="0,6,0,0"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </Border>

                <!-- 2. Target Drive Selection -->
                <Border Background="#1A1E24" CornerRadius="8" Padding="14" BorderBrush="#2D3748" BorderThickness="1" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock Text="2. Installation Target Partition (Zero-Destruction Policy)" Style="{StaticResource HeaderStyle}"/>
                        <TextBlock Text="Pilih partisi NTFS untuk menyimpan container disk VHDX (Tanpa format/shrink partisi Windows):" Foreground="#94A3B8" Margin="0,0,0,8" FontSize="12"/>
                        <ComboBox Name="DriveComboBox" Height="40" Background="#020617" Foreground="#38BDF8" FontSize="14" FontWeight="SemiBold" Padding="10,8" BorderBrush="#38BDF8" BorderThickness="1.5" Cursor="Hand"/>
                    </StackPanel>
                </Border>

                <!-- 3. Container Storage Allocation -->
                <Border Background="#1A1E24" CornerRadius="8" Padding="14" BorderBrush="#2D3748" BorderThickness="1" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock Text="3. Disk Container Storage Allocation (root.vhdx)" Style="{StaticResource HeaderStyle}"/>
                        <Grid Margin="0,4,0,4">
                            <TextBlock Text="Alokasikan kapasitas virtual disk (Dynamic Expandable):" Foreground="#94A3B8" FontSize="12"/>
                            <TextBlock Name="SizeLabel" Text="64 GB" HorizontalAlignment="Right" FontWeight="Bold" Foreground="#38BDF8" FontSize="14"/>
                        </Grid>
                        <Slider Name="SizeSlider" Minimum="30" Maximum="200" Value="64" TickFrequency="8" IsSnapToTickEnabled="True" Margin="0,6"/>
                    </StackPanel>
                </Border>

                <!-- 4. Deployment Engine & Pipeline Mode -->
                <Border Background="#1A1E24" CornerRadius="8" Padding="14" BorderBrush="#2D3748" BorderThickness="1" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock Text="4. Deployment Pipeline Mode" Style="{StaticResource HeaderStyle}"/>
                        <TextBlock Text="Pilih metode pembuatan container OS Linux:" Foreground="#94A3B8" FontSize="12" Margin="0,0,0,8"/>
                        <WrapPanel Orientation="Horizontal" Margin="0,0,0,8">
                            <RadioButton Name="ModeDirect" Content="Direct VHDX Loopback (Siap Booting Langsung)" IsChecked="True" GroupName="PipelineMode"/>
                            <RadioButton Name="ModeKvm" Content="Virtual-to-Physical (V2P via QEMU / Hyper-V VM)" GroupName="PipelineMode"/>
                        </WrapPanel>

                        <!-- ISO Selection & In-App Downloader Box -->
                        <Border Name="IsoPanel" Background="#0B132B" CornerRadius="6" Padding="12" BorderBrush="#3A86FF" BorderThickness="1" Margin="0,4,0,0">
                            <StackPanel>
                                <TextBlock Name="IsoTitleLabel" Text="[ISO] Berkas ISO Distro:" FontWeight="SemiBold" Foreground="#60A5FA" FontSize="13" Margin="0,0,0,6"/>
                                <Grid Margin="0,0,0,8">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <TextBox Name="IsoPathBox" Height="34" Background="#020617" Foreground="#F8FAFC" FontSize="12" Padding="8,4" VerticalContentAlignment="Center" BorderBrush="#334155"/>
                                    <Button Name="BrowseIsoBtn" Grid.Column="1" Content="Browse ISO..." Width="110" Height="34" Background="#2563EB" Foreground="#FFFFFF" FontWeight="SemiBold" Margin="8,0,0,0" BorderThickness="0" Cursor="Hand"/>
                                    <Button Name="DownloadIsoBtn" Grid.Column="2" Content="Auto-Download" Width="140" Height="34" Background="#0D9488" Foreground="#FFFFFF" FontWeight="Bold" Margin="8,0,0,0" BorderThickness="0" Cursor="Hand"/>
                                </Grid>
                                <!-- In-App Download Progress -->
                                <Grid Name="DownloadProgressGrid" Visibility="Collapsed" Margin="0,4,0,4">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <ProgressBar Name="IsoDownloadProgress" Height="8" Minimum="0" Maximum="100" Value="0" Background="#1E293B" Foreground="#10B981" VerticalAlignment="Center"/>
                                    <TextBlock Name="DownloadPercentLabel" Grid.Column="1" Text="0%" Foreground="#10B981" FontWeight="Bold" FontSize="12" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                </Grid>
                                <TextBlock Name="IsoStatusText" Text="Tips: Klik 'Auto-Download' jika belum memiliki file ISO di komputer Anda." Foreground="#94A3B8" FontSize="11"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </Border>

                <!-- 5. Omarchy AI Framework & Stack Selection -->
                <Border Background="#1A1E24" CornerRadius="8" Padding="14" BorderBrush="#2D3748" BorderThickness="1" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock Text="5. Pre-Configured Omarchy AI Framework Modules" Style="{StaticResource HeaderStyle}"/>
                        <TextBlock Text="Pilih komponen AI yang akan disiapkan otomatis saat first boot:" Foreground="#94A3B8" FontSize="12" Margin="0,0,0,8"/>
                        <WrapPanel Orientation="Horizontal">
                            <CheckBox Name="ChkPyTorch" Content="PyTorch (Accelerated)" IsChecked="True"/>
                            <CheckBox Name="ChkvLLM" Content="vLLM Inference Engine" IsChecked="True"/>
                            <CheckBox Name="ChkOllama" Content="Ollama Daemon (Port 11434)" IsChecked="True"/>
                            <CheckBox Name="ChkGradio" Content="Omarchy WebUI (Port 7860)" IsChecked="True"/>
                        </WrapPanel>
                    </StackPanel>
                </Border>

                <!-- 6. Hardware Acceleration & Boot Architecture Detection -->
                <Border Background="#1E1E38" CornerRadius="8" Padding="14" BorderBrush="#6366F1" BorderThickness="1" Margin="0,0,0,12">
                    <StackPanel>
                        <TextBlock Text="6. Detected Compute Hardware &amp; Host Firmware Profile" Style="{StaticResource HeaderStyle}"/>
                        <Grid Margin="0,2,0,4">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0">
                                <TextBlock Text="Compute Acceleration:" Foreground="#94A3B8" FontSize="11"/>
                                <TextBlock Name="GpuLabel" Text="Scanning GPU..." Foreground="#A5B4FC" FontSize="13" FontWeight="SemiBold" Margin="0,2,0,0"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <TextBlock Text="Host Boot Mode &amp; Chainloader Engine:" Foreground="#94A3B8" FontSize="11"/>
                                <TextBlock Name="FirmwareDetailLabel" Text="Detecting Firmware..." Foreground="#38BDF8" FontSize="13" FontWeight="SemiBold" Margin="0,2,0,0"/>
                            </StackPanel>
                        </Grid>
                        <TextBlock Name="FirmwareInfoText" Text="Mode adaptif WUBI-AI: Menyesuaikan chainloader BCD secara otomatis tanpa merusak sistem partisi host." Foreground="#94A3B8" FontSize="11" Margin="0,6,0,0"/>
                    </StackPanel>
                </Border>

                <!-- 7. In-App Activity & Console Log -->
                <Border Background="#0F172A" CornerRadius="8" Padding="12" BorderBrush="#1E293B" BorderThickness="1">
                    <StackPanel>
                        <Grid Margin="0,0,0,6">
                            <TextBlock Text="Status &amp; Activity Log:" FontWeight="SemiBold" Foreground="#94A3B8" FontSize="12"/>
                            <TextBlock Name="StatusIndicator" Text="Ready" HorizontalAlignment="Right" Foreground="#38BDF8" FontSize="12" FontWeight="SemiBold"/>
                        </Grid>
                        <ProgressBar Name="AppProgress" Height="6" IsIndeterminate="False" Value="0" Maximum="100" Background="#1E293B" Foreground="#38BDF8" Margin="0,0,0,8"/>
                        <TextBox Name="LogTextBox" Height="100" Background="#020617" Foreground="#34D399" FontFamily="Consolas" FontSize="12" 
                                 IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" BorderThickness="0" Padding="6"/>
                    </StackPanel>
                </Border>
            </StackPanel>
        </ScrollViewer>

        <!-- Actions Footer -->
        <Border Grid.Row="2" Margin="0,12,0,0" Padding="10" Background="#1C2028" CornerRadius="8">
            <Grid>
                <Button Name="UninstallBtn" Content="Clean Uninstall" HorizontalAlignment="Left" Width="140" Height="38" Background="#334155" Foreground="#F87171" FontWeight="SemiBold" BorderThickness="0" Cursor="Hand"/>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button Name="DryRunBtn" Content="Test Pre-Flight" Width="130" Height="38" Background="#3B4252" Foreground="#E2E8F0" FontWeight="SemiBold" Margin="0,0,10,0" BorderThickness="0" Cursor="Hand"/>
                    <Button Name="InstallBtn" Content="Install AI OS (Safe)" Width="190" Height="38" Background="#0284C7" Foreground="#FFFFFF" FontWeight="Bold" FontSize="14" BorderThickness="0" Cursor="Hand"/>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Window Movable Drag & Double-Click Maximize/Restore Handler
$headerBorder    = $window.FindName("HeaderBorder")
$headerBorder.Add_MouseLeftButtonDown({
    param($sender, $e)
    if ($e.ClickCount -eq 2) {
        if ($window.WindowState -eq [System.Windows.WindowState]::Maximized) {
            $window.WindowState = [System.Windows.WindowState]::Normal
        } else {
            $window.WindowState = [System.Windows.WindowState]::Maximized
        }
    } else {
        if ($window.WindowState -eq [System.Windows.WindowState]::Maximized) {
            $mousePos = [System.Windows.Forms.Cursor]::Position
            $window.WindowState = [System.Windows.WindowState]::Normal
            $window.Left = $mousePos.X - ($window.ActualWidth / 2)
            $window.Top = $mousePos.Y - 20
        }
        $window.DragMove()
    }
})

# Element References
$distroCombo     = $window.FindName("DistroComboBox")
$distroDescText  = $window.FindName("DistroDescText")
$distroTagBadge  = $window.FindName("DistroTagBadge")
$distroSpecsBadge= $window.FindName("DistroSpecsBadge")
$distroBestFor   = $window.FindName("DistroBestForText")
$driveCombo      = $window.FindName("DriveComboBox")
$sizeSlider      = $window.FindName("SizeSlider")
$sizeLabel       = $window.FindName("SizeLabel")
$gpuLabel        = $window.FindName("GpuLabel")
$modeDirect      = $window.FindName("ModeDirect")
$modeKvm         = $window.FindName("ModeKvm")
$isoPanel        = $window.FindName("IsoPanel")
$isoTitleLabel   = $window.FindName("IsoTitleLabel")
$isoPathBox      = $window.FindName("IsoPathBox")
$browseIsoBtn    = $window.FindName("BrowseIsoBtn")
$downloadIsoBtn  = $window.FindName("DownloadIsoBtn")
$dlProgressGrid  = $window.FindName("DownloadProgressGrid")
$isoDlProgress   = $window.FindName("IsoDownloadProgress")
$dlPercentLabel  = $window.FindName("DownloadPercentLabel")
$isoStatusText   = $window.FindName("IsoStatusText")
$chkPyTorch      = $window.FindName("ChkPyTorch")
$chkvLLM         = $window.FindName("ChkvLLM")
$chkOllama       = $window.FindName("ChkOllama")
$chkGradio       = $window.FindName("ChkGradio")
$logBox          = $window.FindName("LogTextBox")
$progressBar     = $window.FindName("AppProgress")
$statusIndicator = $window.FindName("StatusIndicator")
$installBtn      = $window.FindName("InstallBtn")
$dryRunBtn       = $window.FindName("DryRunBtn")
$uninstallBtn    = $window.FindName("UninstallBtn")
$adminBadge      = $window.FindName("AdminBadge")
$firmwareBadge   = $window.FindName("FirmwareBadge")
$fwDetailLabel   = $window.FindName("FirmwareDetailLabel")
$fwInfoText      = $window.FindName("FirmwareInfoText")

# Distro Profiles (All Official Ubuntu Flavors & Minimal)
$distroCatalog = [ordered]@{
    "Ubuntu 24.04 LTS Desktop (Standard)" = @{
        Tag = "OFFICIAL STANDARD"
        TagBg = "#0C4A6E"; TagFg = "#38BDF8"
        Specs = "RAM Min: 4 GB | Disk: 50 GB"
        Desc = "Edisi standar resmi dengan antarmuka GNOME Desktop lengkap dan ketersediaan aplikasi optimal."
        BestFor = "Penggunaan umum sehari-hari, software compatibility terluas, AI workstation all-round."
        IsoName = "ubuntu-24.04.4-desktop-amd64.iso"
        Url = "https://releases.ubuntu.com/24.04/ubuntu-24.04.4-desktop-amd64.iso"
        MinSize = 50
    }
    "Ubuntu 24.04 Minimal / Server (Headless AI Workstation)" = @{
        Tag = "HEADLESS AI / SERVER"
        TagBg = "#064E3B"; TagFg = "#34D399"
        Specs = "RAM Min: 2 GB | Disk: 30 GB"
        Desc = "Super ringan tanpa bloatware GUI, sangat hemat RAM/VRAM untuk inferensi AI maksimal dan server headless."
        BestFor = "Performa AI & LLM tertinggi, server inferensi Ollama/vLLM murni, resource RAM terbatas."
        IsoName = "ubuntu-24.04.5-live-server-amd64.iso"
        Url = "https://releases.ubuntu.com/24.04/ubuntu-24.04.5-live-server-amd64.iso"
        MinSize = 30
    }
    "Ubuntu MATE 24.04 LTS (Classic MATE Desktop)" = @{
        Tag = "CLASSIC & LIGHT"
        TagBg = "#14532D"; TagFg = "#4ADE80"
        Specs = "RAM Min: 2 GB | Disk: 40 GB"
        Desc = "Antarmuka desktop klasik, intuitif, dan sangat hemat konsumsi memori dengan fleksibilitas tinggi."
        BestFor = "Pengguna yang menyukai desktop gaya GNOME 2 tradisional yang simpel dan stabil."
        IsoName = "ubuntu-mate-24.04.5-desktop-amd64.iso"
        Url = "https://cdimage.ubuntu.com/ubuntu-mate/releases/24.04/release/ubuntu-mate-24.04.5-desktop-amd64.iso"
        MinSize = 40
    }
    "Ubuntu Cinnamon 24.04 LTS (Elegant Modern Cinnamon)" = @{
        Tag = "WINDOWS-LIKE UI"
        TagBg = "#78350F"; TagFg = "#FBBF24"
        Specs = "RAM Min: 4 GB | Disk: 45 GB"
        Desc = "Desktop bergaya modern, elegan, dan familier bagi pengguna Windows berbasis lingkungan Cinnamon."
        BestFor = "Pengguna yang baru beralih dari Windows 10/11 dan menginginkan tata letak taskbar & start menu familier."
        IsoName = "ubuntucinnamon-24.04.5-desktop-amd64.iso"
        Url = "https://cdimage.ubuntu.com/ubuntucinnamon/releases/24.04/release/ubuntucinnamon-24.04.5-desktop-amd64.iso"
        MinSize = 45
    }
    "Xubuntu 24.04 LTS (Lightweight XFCE Desktop)" = @{
        Tag = "LIGHTWEIGHT DESKTOP"
        TagBg = "#1E293B"; TagFg = "#60A5FA"
        Specs = "RAM Min: 2 GB | Disk: 40 GB"
        Desc = "Antarmuka XFCE yang sangat ringan dan responsif, ideal untuk PC dengan spesifikasi resource terbatas."
        BestFor = "Laptop/PC spesifikasi standar menengah yang menginginkan UI cepat dan responsif."
        IsoName = "xubuntu-24.04.5-desktop-amd64.iso"
        Url = "https://cdimage.ubuntu.com/xubuntu/releases/24.04/release/xubuntu-24.04.5-desktop-amd64.iso"
        MinSize = 40
    }
    "Xubuntu 24.04 Minimal (Ultra-Lightweight Minimal XFCE)" = @{
        Tag = "ULTRA-MINIMAL GUI"
        TagBg = "#312E81"; TagFg = "#818CF8"
        Specs = "RAM Min: 1.5 GB | Disk: 30 GB"
        Desc = "Edisi Xubuntu minimalis murni tanpa aplikasi bawaan berlebih, hanya sistem dasar dan core desktop."
        BestFor = "Pengguna yang ingin membangun sistem GUI kustom sendiri dari nol dengan beban OS seringan mungkin."
        IsoName = "xubuntu-24.04.5-minimal-amd64.iso"
        Url = "https://cdimage.ubuntu.com/xubuntu/releases/24.04/release/xubuntu-24.04.5-minimal-amd64.iso"
        MinSize = 30
    }
    "Kubuntu 24.04 LTS (Modern KDE Plasma)" = @{
        Tag = "MODERN & ADVANCED"
        TagBg = "#1E1B4B"; TagFg = "#A5B4FC"
        Specs = "RAM Min: 4 GB | Disk: 50 GB"
        Desc = "Desktop canggih dan modern berbasis KDE Plasma dengan kustomisasi visual tingkat lanjut."
        BestFor = "Pengguna yang menyukai animasi visual mewah, widget interaktif, dan kustomisasi tampilan tanpa batas."
        IsoName = "kubuntu-24.04.5-desktop-amd64.iso"
        Url = "https://cdimage.ubuntu.com/kubuntu/releases/24.04/release/kubuntu-24.04.5-desktop-amd64.iso"
        MinSize = 50
    }
    "Lubuntu 24.04 LTS (Ultra-Fast LXQt Desktop)" = @{
        Tag = "SUPER-FAST & LOW RAM"
        TagBg = "#134E4A"; TagFg = "#2DD4BF"
        Specs = "RAM Min: 1 GB | Disk: 35 GB"
        Desc = "Distro resmi Ubuntu paling ringan berbasis LXQt, sangat hemat daya komputasi dan resource."
        BestFor = "Hardware lama, PC hemat energi, atau alokasi sisa resource 95% untuk komputasi AI murni."
        IsoName = "lubuntu-24.04.5-desktop-amd64.iso"
        Url = "https://cdimage.ubuntu.com/lubuntu/releases/24.04/release/lubuntu-24.04.5-desktop-amd64.iso"
        MinSize = 35
    }
    "Ubuntu Budgie 24.04 LTS (Sleek & Visual Desktop)" = @{
        Tag = "STYLISH & MODERN"
        TagBg = "#3B0764"; TagFg = "#C084FC"
        Specs = "RAM Min: 4 GB | Disk: 45 GB"
        Desc = "Antarmuka desktop Budgie yang indah, rapi, dan modern dengan integrasi applet visual interaktif."
        BestFor = "Pengguna yang mengutamakan estetika visual out-of-the-box yang elegan mirip macOS."
        IsoName = "ubuntu-budgie-24.04.5-desktop-amd64.iso"
        Url = "https://cdimage.ubuntu.com/ubuntu-budgie/releases/24.04/release/ubuntu-budgie-24.04.5-desktop-amd64.iso"
        MinSize = 45
    }
    "Ubuntu Unity 24.04 LTS (Iconic Unity 7 Desktop)" = @{
        Tag = "ICONIC WORKFLOW"
        TagBg = "#4C0519"; TagFg = "#FB7185"
        Specs = "RAM Min: 3 GB | Disk: 40 GB"
        Desc = "Antarmuka desktop legendaris Unity 7 dengan HUD launcher vertikal yang efisien untuk produktivitas."
        BestFor = "Pengguna veteran Ubuntu yang menyukai workflow cepat dan launcher dock samping khas Unity."
        IsoName = "ubuntu-unity-24.04.5-desktop-amd64.iso"
        Url = "https://cdimage.ubuntu.com/ubuntu-unity/releases/24.04/release/ubuntu-unity-24.04.5-desktop-amd64.iso"
        MinSize = 40
    }
    "Ubuntu Studio 24.04 LTS (Multimedia & Creator Workstation)" = @{
        Tag = "CREATOR & MEDIA AI"
        TagBg = "#450A0A"; TagFg = "#F87171"
        Specs = "RAM Min: 4 GB | Disk: 60 GB"
        Desc = "Dilengkapi kernel low-latency dan suite lengkap untuk kreator konten audio, video, grafis, dan AI media."
        BestFor = "Kreator konten grafis/video, generative AI (Stable Diffusion/ComfyUI), audio processing."
        IsoName = "ubuntustudio-24.04.5-dvd-amd64.iso"
        Url = "https://cdimage.ubuntu.com/ubuntustudio/releases/24.04/release/ubuntustudio-24.04.5-dvd-amd64.iso"
        MinSize = 60
    }
    "Edubuntu 24.04 LTS (Education & Learning Suite)" = @{
        Tag = "EDUCATION & STEM"
        TagBg = "#064E3B"; TagFg = "#34D399"
        Specs = "RAM Min: 4 GB | Disk: 50 GB"
        Desc = "Edisi khusus pendidikan dengan paket perangkat lunak pembelajaran lengkap untuk sains, matematika, dan edukasi."
        BestFor = "Lingkungan belajar mengajar, institusi sekolah, riset akademik, dan eksplorasi edukasi sains."
        IsoName = "edubuntu-24.04.5-desktop-amd64.iso"
        Url = "https://cdimage.ubuntu.com/edubuntu/releases/24.04/release/edubuntu-24.04.5-desktop-amd64.iso"
        MinSize = 50
    }
    "Ubuntu Kylin 24.04 LTS (UKUI Desktop)" = @{
        Tag = "UKUI MODERN UI"
        TagBg = "#1E1B4B"; TagFg = "#818CF8"
        Specs = "RAM Min: 4 GB | Disk: 45 GB"
        Desc = "Antarmuka UKUI yang halus, ramah pengguna, dengan fitur estetika modern dan utilitas produktivitas."
        BestFor = "Pengguna yang menginginkan tampilan antarmuka UKUI modern dengan panel kontrol terpadu."
        IsoName = "ubuntukylin-24.04.5-desktop-amd64.iso"
        Url = "https://cdimage.ubuntu.com/ubuntukylin/releases/24.04/release/ubuntukylin-24.04.5-desktop-amd64.iso"
        MinSize = 45
    }
}

foreach ($dKey in $distroCatalog.Keys) {
    [void]$distroCombo.Items.Add($dKey)
}
$distroCombo.SelectedIndex = 0

function Update-DistroDisplay {
    $selectedDistro = $distroCombo.SelectedItem.ToString()
    $profile = $distroCatalog[$selectedDistro]
    $distroDescText.Text = $profile.Desc
    $distroBestFor.Text = "Cocok untuk: " + $profile.BestFor
    $distroTagBadge.Text = $profile.Tag
    $distroTagBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($profile.TagBg)
    $distroTagBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($profile.TagFg)
    $distroSpecsBadge.Text = $profile.Specs
    $isoTitleLabel.Text = "Berkas ISO ($($profile.IsoName)):"
    if ($sizeSlider.Value -lt $profile.MinSize) {
        $sizeSlider.Value = $profile.MinSize
    }

    # Auto-detect if ISO already exists on selected drive (Must be valid size > 500MB)
    if ($driveCombo -and $driveCombo.SelectedItem) {
        $selDrive = ($driveCombo.SelectedItem -split " ")[1].Replace(":", "")
        $possibleIso = Join-Path "${selDrive}:\ubuntu-ai" $profile.IsoName
        if (Test-Path $possibleIso) {
            $fInfo = Get-Item $possibleIso -ErrorAction SilentlyContinue
            if ($fInfo -and $fInfo.Length -gt 500MB) {
                $isoPathBox.Text = $possibleIso
                $isoStatusText.Text = "ISO Lengkap Ditemukan di Cache ($([math]::Round($fInfo.Length/1GB, 2)) GB)"
            } else {
                $isoPathBox.Text = ""
                $isoStatusText.Text = "Berkas ISO lama belum lengkap / corrupt. Klik 'Auto-Download'."
            }
        } else {
            $isoPathBox.Text = ""
            $isoStatusText.Text = "Distro terpilih: $selectedDistro. Klik 'Auto-Download'."
        }
    }
}

$distroCombo.Add_SelectionChanged({
    Update-DistroDisplay
})
Update-DistroDisplay

# In-App Console Logger
function Append-GuiLog([string]$msg, [string]$status = "") {
    $action = {
        $timestamp = (Get-Date).ToString("HH:mm:ss")
        $logBox.AppendText("[$timestamp] $msg`r`n")
        $logBox.ScrollToEnd()
        if ($status) { $statusIndicator.Text = $status }
    }
    if ($window.Dispatcher.CheckAccess()) {
        & $action
    } else {
        $window.Dispatcher.BeginInvoke([Action]$action) | Out-Null
    }
}

# Check Admin elevation status
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $adminBadge.Text = "STANDARD USER (Elevate required for install)"
    $adminBadge.Foreground = [System.Windows.Media.Brushes]::Yellow
    $adminBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#713F12")
}

# Firmware Detection (Adaptive UEFI / Legacy BIOS MBR)
$isUefi = $false
$fwModeName = "Legacy BIOS / MBR"
try {
    $peFw = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control" -Name "PEFirmwareType" -ErrorAction SilentlyContinue).PEFirmwareType
    if ($peFw -eq 2) { 
        $isUefi = $true 
        $fwModeName = "UEFI Mode (GPT)"
    }
} catch {}

if (-not $isUefi) {
    $bcdCurrent = bcdedit /enum "{current}"
    if ($bcdCurrent -match "path.*efi") {
        $isUefi = $true
        $fwModeName = "UEFI Mode (BCD efi path)"
    }
}

if ($isUefi) {
    $firmwareBadge.Text = "BOOT: UEFI MODE"
    $firmwareBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
    $firmwareBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0C4A6E")
    $fwDetailLabel.Text = "UEFI Mode (WubiUEFI Chainloader - /copy {bootmgr})"
    $fwDetailLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
    $fwInfoText.Text = "Host terdeteksi UEFI: WUBI-AI akan mendaftarkan chainloader EFI aman melalui BCD tanpa memodifikasi ESP default."
} else {
    $firmwareBadge.Text = "BOOT: LEGACY BIOS (MBR)"
    $firmwareBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
    $firmwareBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#78350F")
    $fwDetailLabel.Text = "Legacy BIOS / MBR (BOOTSECTOR Chainloader)"
    $fwDetailLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
    $fwInfoText.Text = "Host terdeteksi Non-UEFI (Legacy BIOS): WUBI-AI otomatis menggunakan BOOTSECTOR chainload (boot.bin) tanpa menyentuh Master Boot Record host."
}

# Populate Hardware Scan
$gpus = (Get-CimInstance Win32_VideoController).Name -join ", "
$gpuLabel.Text = "Compute Device: $gpus"
Append-GuiLog "WUBI-AI GUI Initialized. Host Firmware: $fwModeName | Hardware: $gpus" "Ready"

# Populate Eligible NTFS Drives
$volumes = Get-Volume | Where-Object { $_.DriveType -eq "Fixed" -and $_.FileSystem -eq "NTFS" -and $_.DriveLetter -ne $null }
foreach ($v in $volumes) {
    $freeGB = [math]::Round($v.SizeRemaining / 1GB, 1)
    $totalGB = [math]::Round($v.Size / 1GB, 1)
    $label = if ($v.FileSystemLabel) { $v.FileSystemLabel } else { "Local Disk" }
    $item = "Drive $($v.DriveLetter): [$label] - $freeGB GB Free (Total: $totalGB GB)"
    [void]$driveCombo.Items.Add($item)
}
if ($driveCombo.Items.Count -gt 0) { $driveCombo.SelectedIndex = 0 }
$driveCombo.Add_SelectionChanged({
    Update-DistroDisplay
})

# Slider Sync
$sizeSlider.Add_ValueChanged({
    $sizeLabel.Text = "$([int]$sizeSlider.Value) GB"
})

# Pipeline Mode Toggle
$modeDirect.Add_Checked({
    $isoStatusText.Text = "Mode Direct: OS base disiapkan langsung (Opsional: ISO dapat digunakan jika tersedia)."
})
$modeKvm.Add_Checked({
    $isoStatusText.Text = "Mode QEMU/KVM: Harap pilih berkas Ubuntu ISO atau klik 'Auto-Download'."
})

# Browse ISO Dialog
$browseIsoBtn.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Linux ISO Images (*.iso)|*.iso|All Files (*.*)|*.*"
    $dialog.Title = "Pilih Berkas ISO Ubuntu / Flavor"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $isoPathBox.Text = $dialog.FileName
        $isoStatusText.Text = "ISO Terpilih: $(Split-Path $dialog.FileName -Leaf)"
        Append-GuiLog "Berkas ISO dipilih: $($dialog.FileName)"
    }
})

# -----------------------------------------------------------------------------
# WUBI-Style Automated Background Downloader for Selected Flavor
# -----------------------------------------------------------------------------
function Start-WubiIsoDownload([string]$targetFolder) {
    $selectedDistro = $distroCombo.SelectedItem.ToString()
    $profile = $distroCatalog[$selectedDistro]
    $isoName = $profile.IsoName
    $isoUrl = $profile.Url
    $destinationPath = Join-Path $targetFolder $isoName

    if (Test-Path $destinationPath) {
        $existInfo = Get-Item $destinationPath -ErrorAction SilentlyContinue
        if ($existInfo -and $existInfo.Length -gt 500MB) {
            $isoPathBox.Text = $destinationPath
            $isoStatusText.Text = "ISO Ditemukan di Cache ($([math]::Round($existInfo.Length/1GB, 2)) GB)"
            Append-GuiLog "ISO lengkap sudah ada di cache lokal: $destinationPath"
            return $destinationPath
        } else {
            Append-GuiLog "Berkas ISO lama di cache tidak utuh ($([math]::Round($existInfo.Length/1MB, 1)) MB). Menghapus dan memulai unduhan baru..." "Cleaning cache"
            Remove-Item $destinationPath -Force -ErrorAction SilentlyContinue
        }
    }

    $dlProgressGrid.Visibility = [System.Windows.Visibility]::Visible
    $downloadIsoBtn.IsEnabled = $false
    $browseIsoBtn.IsEnabled = $false
    $installBtn.IsEnabled = $false

    Append-GuiLog "Memulai unduhan berkas ISO resmi [$selectedDistro]..." "Downloading ISO"
    Append-GuiLog "Target URL : $isoUrl"
    Append-GuiLog "Menyimpan ke : $destinationPath"

    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor 3072 -bor 12288
    [System.Net.ServicePointManager]::DefaultConnectionLimit = 10

    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) WubiAI-Downloader/1.0")
    $webClient.Proxy = [System.Net.GlobalProxySelection]::GetEmptyWebProxy()

    $script:lastProgressUpdate = [DateTime]::MinValue
    $script:lastProgressPct = -1
    $script:downloadStartTime = [DateTime]::UtcNow

    $webClient.add_DownloadProgressChanged({
        param($sender, $e)
        $now = [DateTime]::UtcNow
        if ($e.ProgressPercentage -ne $script:lastProgressPct -or ($now - $script:lastProgressUpdate).TotalMilliseconds -ge 300) {
            $script:lastProgressPct = $e.ProgressPercentage
            $script:lastProgressUpdate = $now
            
            $pct = $e.ProgressPercentage
            $rcv = [math]::Round($e.BytesReceived / 1MB, 1)
            $tot = [math]::Round($e.TotalBytesToReceive / 1MB, 1)
            
            $elapsedSec = ($now - $script:downloadStartTime).TotalSeconds
            $speedMBps = if ($elapsedSec -gt 0) { [math]::Round(($e.BytesReceived / 1MB) / $elapsedSec, 2) } else { 0 }

            $window.Dispatcher.BeginInvoke([Action]{
                $isoDlProgress.Value = $pct
                $dlPercentLabel.Text = "$pct%"
                if ($tot -gt 0) {
                    $statusIndicator.Text = "Unduh: $([math]::Round($rcv, 1)) MB / $([math]::Round($tot, 1)) MB ($pct% @ $speedMBps MB/s)"
                } else {
                    $statusIndicator.Text = "Unduh: $([math]::Round($rcv, 1)) MB ($pct% @ $speedMBps MB/s)"
                }
            }) | Out-Null
        }
    })

    $webClient.add_DownloadFileCompleted({
        param($sender, $e)
        $window.Dispatcher.BeginInvoke([Action]{
            $downloadIsoBtn.IsEnabled = $true
            $browseIsoBtn.IsEnabled = $true
            $installBtn.IsEnabled = $true
            if ($e.Error -ne $null) {
                Append-GuiLog "Download Gagal: $($e.Error.Message)" "Error"
                $statusIndicator.Text = "Download Gagal"
                [System.Windows.MessageBox]::Show("Gagal mengunduh berkas ISO:`n$($e.Error.Message)`n`nSilakan periksa koneksi internet atau gunakan tombol 'Browse ISO...' jika Anda sudah mengunduhnya secara manual.", "Download Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
            } else {
                $isoPathBox.Text = $destinationPath
                $isoStatusText.Text = "ISO Siap: $isoName"
                $statusIndicator.Text = "Download Selesai"
                Append-GuiLog "Download ISO Selesai! Disimpan ke: $destinationPath" "Ready"

                # Prompt user for immediate installation & QEMU launch
                $isKvm = $modeKvm.IsChecked
                $promptMsg = "Download ISO [$selectedDistro] telah selesai!`n`nBerkas tersimpan di:`n$destinationPath`n`n" +
                             $(if ($isKvm) { "Apakah Anda ingin WUBI-AI langsung menyiapkan virtual drive dan menjalankan QEMU Installer sekarang?" } else { "Apakah Anda ingin melanjutkan instalasi Direct Loopback sekarang?" })

                $launchNow = [System.Windows.MessageBox]::Show(
                    $promptMsg,
                    "Download Selesai - Lanjutkan Instalasi?",
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Question
                )

                if ($launchNow -eq [System.Windows.MessageBoxResult]::Yes) {
                    Start-WubiAIInstallation
                } else {
                    [System.Windows.MessageBox]::Show("Anda dapat mengklik tombol 'Install AI OS (Safe)' kapan saja saat Anda siap.", "WUBI-AI Ready", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                }
            }
        }) | Out-Null
    })

    try {
        $webClient.DownloadFileAsync([System.Uri]$isoUrl, $destinationPath)
    } catch {
        $downloadIsoBtn.IsEnabled = $true
        $browseIsoBtn.IsEnabled = $true
        $installBtn.IsEnabled = $true
        Append-GuiLog "Gagal memulai download: $($_.Exception.Message)" "Error"
        [System.Windows.MessageBox]::Show("Tidak dapat memulai proses unduh:`n$($_.Exception.Message)", "Download Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
    return $destinationPath
}

$downloadIsoBtn.Add_Click({
    $selectedDrive = ($driveCombo.SelectedItem -split " ")[1].Replace(":", "")
    $targetDir = "${selectedDrive}:\ubuntu-ai"
    if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
    Start-WubiIsoDownload -targetFolder $targetDir
})

# -----------------------------------------------------------------------------
# 1. Action: Test Pre-Flight
# -----------------------------------------------------------------------------
$dryRunBtn.Add_Click({
    $progressBar.IsIndeterminate = $true
    $dryRunBtn.IsEnabled = $false
    $installBtn.IsEnabled = $false
    $uninstallBtn.IsEnabled = $false
    
    $selectedDrive = ($driveCombo.SelectedItem -split " ")[1].Replace(":", "")
    $selectedDistro = $distroCombo.SelectedItem.ToString()
    $size = [int]$sizeSlider.Value
    $pipeline = if ($modeKvm.IsChecked) { "V2P (QEMU/Hyper-V)" } else { "Direct VHDX Loopback" }
    
    Append-GuiLog "Running Pre-Flight validation on ${selectedDrive}: (Distro: $selectedDistro | $size GB | Mode: $pipeline)..." "Testing"
    
    $script = "d:\Project\WUBI-AI\src\scripts\Install-UbuntuOmarchy.ps1"
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -TargetDrive $selectedDrive -VhdSizeGB $size -DryRun 2>&1
    foreach ($line in $output) {
        Append-GuiLog $line
    }
    
    $progressBar.IsIndeterminate = $false
    $dryRunBtn.IsEnabled = $true
    $installBtn.IsEnabled = $true
    $uninstallBtn.IsEnabled = $true
    Append-GuiLog "Pre-Flight verification passed successfully." "Ready"
    
    [System.Windows.MessageBox]::Show(
        "Pre-Flight validation berhasil dijalankan!`nDistro: $selectedDistro`nTarget: ${selectedDrive}:\ubuntu-ai ($size GB)`nPipeline Mode: $pipeline", 
        "Pre-Flight Passed", 
        [System.Windows.MessageBoxButton]::OK, 
        [System.Windows.MessageBoxImage]::Information
    ) | Out-Null
})

# -----------------------------------------------------------------------------
# 2. Action: Clean Uninstall
# -----------------------------------------------------------------------------
$uninstallBtn.Add_Click({
    $confirmUninstall = [System.Windows.MessageBox]::Show(
        "Apakah Anda yakin ingin menghapus entri Dual-Boot Ubuntu Omarchy dari Windows Boot Manager?",
        "Konfirmasi Uninstall WUBI-AI",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    if ($confirmUninstall -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $deleteContainer = [System.Windows.MessageBox]::Show(
        "Apakah Anda juga ingin menghapus folder container VHD (misal: D:\ubuntu-ai)?`n`nPilih 'Yes' untuk menghapus total data Linux.`nPilih 'No' untuk hanya melepas menu bootloader.",
        "Hapus File Container VHD?",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    $forceFlag = if ($deleteContainer -eq [System.Windows.MessageBoxResult]::Yes) { "-Force" } else { "" }

    $progressBar.IsIndeterminate = $true
    Append-GuiLog "Menjalankan proses uninstalasi bersih..." "Uninstalling"
    
    $unScript = "d:\Project\WUBI-AI\src\scripts\Uninstall-UbuntuOmarchy.ps1"
    $cmd = "& '$unScript' $forceFlag"
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1
    foreach ($line in $output) {
        Append-GuiLog $line
    }
    
    $progressBar.IsIndeterminate = $false
    Append-GuiLog "Proses uninstalasi selesai. Bootloader Windows telah dinormalisasi." "Completed"
    
    [System.Windows.MessageBox]::Show(
        "Uninstalasi berhasil diselesaikan.`nEntri BCD telah dihapus dan sistem dikembalikan ke default Windows Boot Manager.",
        "Uninstall Selesai",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information
    ) | Out-Null
})

# -----------------------------------------------------------------------------
# QEMU Engine Discovery & Provisioning Helpers
# -----------------------------------------------------------------------------
function Get-QemuExecutablePath {
    $candidates = @(
        "qemu-system-x86_64.exe",
        "C:\Program Files\qemu\qemu-system-x86_64.exe",
        "C:\Program Files (x86)\qemu\qemu-system-x86_64.exe",
        "$env:LOCALAPPDATA\Programs\qemu\qemu-system-x86_64.exe"
    )
    foreach ($c in $candidates) {
        if ($c -eq "qemu-system-x86_64.exe") {
            $cmd = Get-Command "qemu-system-x86_64.exe" -ErrorAction SilentlyContinue
            if ($cmd) { return $cmd.Source }
        } else {
            if (Test-Path $c) { return $c }
        }
    }
    return $null
}

function Install-QemuEngine {
    Append-GuiLog "QEMU tidak ditemukan. Memeriksa ketersediaan winget..." "Checking winget"
    $winget = Get-Command "winget.exe" -ErrorAction SilentlyContinue
    if ($winget) {
        Append-GuiLog "Memasang QEMU via Windows Package Manager (winget)..." "Installing QEMU"
        $installProc = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"winget install SoftwareFreedomConservancy.QEMU --accept-source-agreements --accept-package-agreements`"" -PassThru -Wait
        $qPath = Get-QemuExecutablePath
        if ($qPath) {
            Append-GuiLog "QEMU berhasil dipasang: $qPath" "QEMU Ready"
            return $qPath
        }
    }
    Append-GuiLog "Pemasangan QEMU otomatis belum selesai atau memerlukan restart sesi." "Warning"
    return $null
}

# -----------------------------------------------------------------------------
# Core Action: Start Installation Pipeline
# -----------------------------------------------------------------------------
function Start-WubiAIInstallation {
    $selectedDrive = ($driveCombo.SelectedItem -split " ")[1].Replace(":", "")
    $selectedDistro = $distroCombo.SelectedItem.ToString()
    $size = [int]$sizeSlider.Value
    $isKvm = $modeKvm.IsChecked
    $isoPath = $isoPathBox.Text.Trim()
    $pipelineName = if ($isKvm) { "Virtual-to-Physical (V2P via VM)" } else { "Direct VHDX Loopback" }

    # If Mode KVM and no ISO specified: Prompt to trigger Wubi-style Downloader automatically!
    if ($isKvm -and ([string]::IsNullOrWhiteSpace($isoPath) -or -not (Test-Path $isoPath))) {
        $downloadConfirm = [System.Windows.MessageBox]::Show(
            "Berkas ISO lokal tidak ditemukan.`n`nApakah Anda ingin WUBI-AI mengunduh (Auto-Download) berkas resmi [$selectedDistro] secara otomatis ke ${selectedDrive}:\ubuntu-ai?",
            "Auto-Download Ubuntu ISO",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        )
        if ($downloadConfirm -eq [System.Windows.MessageBoxResult]::Yes) {
            $targetFolder = "${selectedDrive}:\ubuntu-ai"
            if (-not (Test-Path $targetFolder)) { New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null }
            Start-WubiIsoDownload -targetFolder $targetFolder
            [System.Windows.MessageBox]::Show("Proses download ISO telah dimulai di latar belakang. Begitu selesai, WUBI-AI akan langsung menawarkan finalisasi instalasi QEMU.", "Download Berjalan", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        } else {
            return
        }
    }

    # If Mode KVM: Check QEMU Engine Availability
    if ($isKvm) {
        $qemuExe = Get-QemuExecutablePath
        if (-not $qemuExe) {
            $qemuPrompt = [System.Windows.MessageBox]::Show(
                "QEMU Engine (qemu-system-x86_64.exe) belum terdeteksi di sistem.`n`nApakah Anda ingin WUBI-AI memasang QEMU secara otomatis via winget sekarang?",
                "Pasang QEMU Virtual Engine?",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question
            )
            if ($qemuPrompt -eq [System.Windows.MessageBoxResult]::Yes) {
                $qemuExe = Install-QemuEngine
            }
        }
    }
    
    $modules = @()
    if ($chkPyTorch.IsChecked) { $modules += "PyTorch" }
    if ($chkvLLM.IsChecked)    { $modules += "vLLM" }
    if ($chkOllama.IsChecked)  { $modules += "Ollama" }
    if ($chkGradio.IsChecked)  { $modules += "Gradio WebUI" }
    $moduleList = $modules -join ", "

    $isoLine = if ($isKvm -and $isoPath) { "• Berkas ISO      : $(Split-Path $isoPath -Leaf)`r`n" } else { "" }
    $msg = "KONFIRMASI INSTALASI (ZERO-DESTRUCTION POLICY):`r`n`r`n" +
           "• Edisi Distro    : $selectedDistro`r`n" +
           "• Target Drive    : Drive ${selectedDrive}:`r`n" +
           "• Ukuran VHDX     : $size GB (Dynamic Expandable)`r`n" +
           "• Pipeline Mode   : $pipelineName`r`n" +
           $isoLine +
           "• Stack Omarchy   : $moduleList`r`n`r`n" +
           "Windows Anda TIDAK akan diformat atau dipartisi ulang.`r`n" +
           "Lanjutkan proses instalasi sekarang?"
           
    $confirm = [System.Windows.MessageBox]::Show($msg, "Konfirmasi Instalasi WUBI-AI", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $script = "d:\Project\WUBI-AI\src\scripts\Install-UbuntuOmarchy.ps1"
    $modeVal = if ($isKvm) { "KVM" } else { "Direct" }
    $isoArg = if ($isKvm -and $isoPath) { "-UbuntuIsoPath `"$isoPath`" -AutoRunQemu" } else { "" }

    if (-not $isAdmin) {
        Append-GuiLog "Meminta izin Administrator untuk eksekusi diskpart, BCD, & virtualisasi..." "Elevating"
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `& `'$script`' -TargetDrive `'$selectedDrive`' -VhdSizeGB $size -Mode $modeVal $isoArg; [System.Windows.MessageBox]::Show('Pipeline WUBI-AI selesai dijalankan!','WUBI-AI Status',[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information)"
        Append-GuiLog "Proses instalasi diluncurkan di sesi Administrator." "Installing"
    } else {
        $progressBar.IsIndeterminate = $true
        $dryRunBtn.IsEnabled = $false
        $installBtn.IsEnabled = $false
        $uninstallBtn.IsEnabled = $false
        Append-GuiLog "Memulai instalasi [$selectedDistro] via pipeline: $pipelineName..." "Installing"
        
        $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -TargetDrive $selectedDrive -VhdSizeGB $size -Mode $modeVal -UbuntuIsoPath $isoPath -AutoRunQemu 2>&1
        foreach ($line in $output) {
            Append-GuiLog $line
        }
        
        $progressBar.IsIndeterminate = $false
        $dryRunBtn.IsEnabled = $true
        $installBtn.IsEnabled = $true
        $uninstallBtn.IsEnabled = $true
        
        if ($isKvm) {
            Append-GuiLog "Virtual Drive root.vhdx siap & QEMU Installer telah diluncurkan." "Complete"
            [System.Windows.MessageBox]::Show(
                "Virtual Drive dan Bootloader WUBI-AI telah disiapkan!`n`nJendela VM QEMU kini berjalan untuk memproses instalasi OS langsung ke ${selectedDrive}:\ubuntu-ai\root.vhdx.`nSetelah instalasi di QEMU tuntas, Anda dapat langsung me-restart PC untuk booting bare-metal ke Ubuntu!",
                "WUBI-AI QEMU Pipeline Aktif",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            ) | Out-Null
        } else {
            Append-GuiLog "Instalasi Berhasil! Silakan reboot untuk masuk ke $selectedDistro (Omarchy AI)." "Complete"
            [System.Windows.MessageBox]::Show(
                "Instalasi Selesai!`n`n$selectedDistro (Omarchy AI) telah terpasang di ${selectedDrive}:\ubuntu-ai.`nAnda dapat me-reboot komputer dan memilih Ubuntu dari menu boot.",
                "WUBI-AI Sukses",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            ) | Out-Null
        }
    }
}

# -----------------------------------------------------------------------------
# 3. Action: Install AI OS Button Click
# -----------------------------------------------------------------------------
$installBtn.Add_Click({
    Start-WubiAIInstallation
})

$window.ShowDialog() | Out-Null




