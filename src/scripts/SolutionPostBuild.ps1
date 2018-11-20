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
			source = "Netmf\4.3\Sagitta.Runtime.netmf43";
			libtarget = "netmf43"
			},
			@{
			source = "Netmf\4.4\Sagitta.Runtime.netmf44";
			target = "netmf44"
			}
		)
	},
	@{
		nuspec = "PervasiveDigital.Sagitta.Runtime.TinyCLR.nuspec";
		package = "Sagitta.Runtime.TinyCLR";
		projects = @(
			@{
				source = "TinyCLR\Sagitta.Runtime.TinyCLR";
				target = "net452";
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

function PrepareNugetPackage([string]$projectName, [string]$netmfVersion) {

	Write-Verbose "PREPARE"

	$nugetBuildDir = $SolutionDir + 'nuget\' + $ConfigurationName + '\' + $projectName + '\'
	$libDir = $nugetBuildDir + "lib\"
	$srcDir = $nugetBuildDir + "src\"

	$projectDir = $SolutionDir + 'netmf' + $netmfVersion + '\' + $projectName + '\'
	$targetDir = $projectDir + 'bin\' + $ConfigurationName + '\'

	mkdir $libDir"\netmf"$netMFVersion"\be" | out-null
	Copy-Item -Path $targetDir"be\*" -Destination $libDir"\netmf"$netMFVersion"\be" -Include "$projectname.dll","$projectname.pdb","$projectname.xml","$projectname.pdbx","$projectname.pe"
	mkdir $libDir"\netmf"$netMFVersion"\le" | out-null
	Copy-Item -Path $targetDir"le\*" -Destination $libDir"\netmf"$netMFVersion"\le" -Include "$projectname.dll","$projectname.pdb","$projectname.xml","$projectname.pdbx","$projectname.pe"
	Copy-Item -Path $targetDir"*" -Destination $libDir"\netmf"$netMFVersion -Include "$projectname.dll","$projectname.pdb","$projectname.xml","$projectname.pdbx","$projectname.pe"
}

function PublishNugetPackage([string]$projectName) {

	Write-Verbose "PUBLISH"

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
	Write-Verbose $job
	$pkgname = $project + "." + $platform
    CleanNugetPackage $job
    #CopySource $project $platform
	foreach ($version in $netmfVersions) {
		PrepareNugetPackage  $pkgname $version
	}
	PublishNugetPackage $project
}
