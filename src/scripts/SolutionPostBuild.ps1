[CmdletBinding()]
param($RepoDir, $SolutionDir, $ConfigurationName, [switch]$Disable)

if(-not ($RepoDir -and $SolutionDir -and $ConfigurationName))
{
	Write-Error "RepoDir, SolutionDir, and ConfigurationName are all required"
	exit 1
}

$buildDir = $SolutionDir + "build\nuget\" + $ConfigurationName + "\"

$jobs = @(
	@{
		nuspec = "PervasiveDigital.Sagitta.Runtime.netmf.nuspec";
		package = "Sagitta.Runtime.netmf";
		projects = @(
			@{
			dir = "netmf\4.3\";
			projectName = "Sagitta.Runtime.netmf43";
			libtarget = "netmf43";
			subdirs = @("\", "\be\", "\le\");
			},
			@{
			dir = "netmf\4.4\";
			projectName = "Sagitta.Runtime.netmf44";
			libtarget = "netmf44";
			subdirs = @("\", "\be\", "\le\");
			}
		)
	},
	@{
		nuspec = "PervasiveDigital.Sagitta.Runtime.TinyCLR.nuspec";
		package = "Sagitta.Runtime.TinyCLR";
		projects = @(
			@{
			dir = "TinyCLR\";
			projectName = "Sagitta.Runtime.TinyCLR";
			libtarget = "net452";
			subdirs = @("\");
			}
		)
	}
)

function CleanNugetPackage($job) {

	Write-Verbose "---- CLEAN ----------------------------------------------------------------------"

	foreach ($project in $job["projects"]) {
		$nugetBuildDir = $buildDir + $job["package"] + "\"
		$libDir = $nugetBuildDir + "lib\"
		$srcDir = $nugetBuildDir + "src\"

		Write-Verbose "Removing $nugetBuildDir"

		if (test-path $nugetBuildDir) { ri -r -fo $nugetBuildDir }
		mkdir $libDir | out-null
		mkdir $srcDir | out-null
	}
}


function CopySource([string]$projectName, [string]$platformName) {

	Write-Verbose "---- COPYSOURCE -----------------------------------------------------------------"

	$nugetBuildDir = $SolutionDir + 'nuget\' + $ConfigurationName + '\' + $projectName + '\'
	$srcDir = $nugetBuildDir + "src\"

	# Copy source files for symbol server
	$sharedProjectName = $projectName + '.Shared\'
	$sharedDir = $SolutionDir + 'shared\' + $sharedProjectName
	Copy-Item -Recurse -Path $sharedDir -Destination $srcDir -Filter "*.cs"
	
	# rename the copied dir to remove the .Shared
	$sharedTargetPath = $srcDir + $sharedProjectName
	Rename-Item -Path $sharedTargetPath -NewName $projectName

	# no longer needed since there are no generated files in shared source projects
	#$target = $srcDir + $projectName
	#if (test-path $target"\obj") { Remove-Item -Recurse $target"\obj" | out-null }
	#if (test-path $target"\bin") { Remove-Item -Recurse $target"\bin" | out-null }
}

function PrepareNugetPackage($job) {

	Write-Verbose "---- PREPARE --------------------------------------------------------------------"

	$nugetBuildDir = $buildDir + $job["package"] + "\"
	$libDir = $nugetBuildDir + "lib\"
	$srcDir = $nugetBuildDir + "src\"

	foreach ($project in $job["projects"]) {
		$projectDir = $SolutionDir + $project["dir"] + $project["projectName"]
		$originDir = $projectDir + "\bin\" + $ConfigurationName
		$projectName = $project["projectName"];

		$destDir = $libDir + $project["libtarget"]
		foreach ($subdir in $project["subdirs"])
		{
			Write-Verbose "Creating $destDir$subdir"
			mkdir $destDir$subdir | out-null
			Write-Verbose "Copying $originDir$subdir to $destDir$subdir"
			Copy-Item -Path "$originDir$subdir*" -Destination "$destDir$subdir" -Include "$projectname.dll","$projectname.pdb","$projectname.xml","$projectname.pdbx","$projectname.pe"
		}
	}
}

function PublishNugetPackage($job) {

	Write-Verbose "---- PUBLISH --------------------------------------------------------------------"

	$nuspec = $SolutionDir + 'nuget\' + $projectName + '.nuspec'
	Write-Verbose "nuspec file $nuspec"

	$nugetBuildDir = $SolutionDir + 'nuget\' + $ConfigurationName + '\' + $projectName + '\'
	$libDir = $nugetBuildDir + "lib\"
	$srcDir = $nugetBuildDir + "src\"
	$nuget = $SolutionDir + "nuget\bin\nuget.exe"

	# Create the nuget package
	$output = $repoDir + $ConfigurationName
	if (-not (test-path $output)) { mkdir $output | out-null }

	$args = 'pack', $nuspec, '-Symbols', '-basepath', $nugetBuildDir, '-OutputDirectory', $output
	& $nuget $args
}

foreach ($job in $jobs) {
	$pkgname = $project + "." + $platform
    CleanNugetPackage $job
    #CopySource $project $platform
	PrepareNugetPackage  $job
#	PublishNugetPackage $project
}
