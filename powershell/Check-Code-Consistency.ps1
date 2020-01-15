$object_path_array = @(
      "C:\dev\project1\*.sql"
    , "C:\dev\project2\*.sql"
)

############################
# File name with no schema #
############################
Write-Host "`r`nThe file name should have the schema prefix:"  -ForegroundColor Cyan

foreach ($object_path in $object_path_array)
{
    $files = Get-ChildItem $object_path -Recurse

    foreach ($file in $files)
    {
        if ($file.FullName | Select-String -Pattern "\Functions\", "\Stored Procedures\", "\Tables\", "\Views" -SimpleMatch -Quiet)
        {
            $object_name = $file.BaseName.split(".")[1] # Strip off the schema prefix

            if (!($object_name))
            {
                "$($file.Name)"
            }
        }
    }   
}

###########################
# File Name = Object Name #
###########################
Write-Host "`r`nThe file name (object name) should be found in the file:"  -ForegroundColor Cyan

foreach ($object_path in $object_path_array)
{
    $files = Get-ChildItem $object_path -Recurse

    foreach ($file in $files)
    {       
        $object_name = $file.BaseName.split(".")[1] # Strip off the schema prefix

        if (!($object_name))
        {
            "$($file.Name) - No schema prefix"
        }
        elseif (!(Select-String -Path $file.FullName -Pattern $object_name -SimpleMatch -Quiet))
        {
            "$($file.Name)"
        }
    }   
}

##########################
# No space in file names #
##########################
Write-Host "`r`nThe file name should not contain spaces:"  -ForegroundColor Cyan

foreach ($object_path in $object_path_array)
{
    $files = Get-ChildItem $object_path -Recurse

    foreach ($file in $files)
    {
        if ($file.BaseName | Select-String -Pattern " " -SimpleMatch -Quiet)
        {
            "$($file.Name)"
        }
    }   
}

##########################
# Check table definition #
##########################
Write-Host "`r`nThe table definition should not contain keywords that could cause a table rebuild:"  -ForegroundColor Cyan

foreach ($object_path in $object_path_array)
{
    $files = Get-ChildItem $object_path -Recurse

    foreach ($file in $files)
    {
        if ($file.FullName | Select-String -Pattern "\Tables\" -SimpleMatch -Quiet)
        {
            # cast(     => convert()
            # between   => >= and <=
            # in (      => or
            # -1.9 * 3  => -(1.9 * 3)
            if (Select-String -Path $file.FullName -Pattern "cast\(", " between ", " in \(", "day\(", "as\s.+-\d" -Quiet)
            {
                "$($file.Name)"
            }
        }
    }   
}

##################
# Check nvarchar #
##################
Write-Host "`r`nString constants should be prefixed with N to make them nvarchar:"  -ForegroundColor Cyan

foreach ($object_path in $object_path_array)
{
    $files = Get-ChildItem $object_path -Recurse

    foreach ($file in $files)
    {
        if ($file.FullName | Select-String -Pattern "\Functions\", "\Stored Procedures\", "\Tables\", "\Views" -SimpleMatch -Quiet)
        {
            if (Select-String -Path $file.FullName -Pattern "=\s*'[^']" -Quiet)
            {
                "$($file.Name)"
            }
        }
    }
}

#######
# xxx #
#######
Write-Host "`r`nDatabase context [xxx] should not be hardcoded in the current database:" -ForegroundColor Cyan
foreach ($object_path in $object_path_array)
{
    if ($object_path | Select-String -Pattern "xxx" -SimpleMatch -Quiet)
    {
        Select-String $object_path -Pattern "xxx." -SimpleMatch
    }
}

###########################################
# Check dbo. in front of table/proc names #
###########################################
Write-Host "`r`nMissing dbo. in front table/proc names:" -ForegroundColor Cyan

foreach ($object_path in $object_path_array)
{
    Select-String $object_path -Pattern "from t_", "join t_" -SimpleMatch
    Select-String $object_path -Pattern "exec p_" -SimpleMatch
    Select-String $object_path -Pattern "execute p_" -SimpleMatch
}

############################################
# Format numbers to #,##0 instead of #,### #
############################################
Write-Host "`r`nFormat numbers to #,##0 instead of #,###:" -ForegroundColor Cyan

$procs = Get-ChildItem "C:\dev\project1\Stored Procedures\*.sql"

foreach ($proc in $procs)
{
    if (Select-String -Path $proc.FullName -Pattern "#,###" -SimpleMatch -Quiet)
    {
        $proc.BaseName
    }
}

##########################
# Detected ALTER PROC in #
##########################
Write-Host "`r`nProc DML needs to start with CREATE instead of ALTER:" -ForegroundColor Cyan

$procs = Get-ChildItem "C:\dev\project1\Stored Procedures\*.sql"

foreach ($proc in $procs)
{
    if (Select-String -Path $proc.FullName -Pattern "alter proc" -SimpleMatch -Quiet)
    {
        $proc.BaseName
    }
}

##############################################################
# LHS should not be the same as RHS in an equality condition #
##############################################################
Write-Host "`r`nLHS should not be the same as RHS in an equality condition:" -ForegroundColor Cyan

$procs = Get-ChildItem "C:\dev\project1\Stored Procedures\*.sql"

foreach ($proc in $procs)
{
    $match_info = Select-String -Path $proc.FullName -Pattern "\s*[^\s\)]+\s*=\s*[^\s\)]+" -AllMatches

    foreach ($match in $match_info.Matches) {

        $lhs, $rhs = $match.value.Split("=")

        $lhs = $lhs.Trim()
        $rhs = $rhs.Trim()

        if ((!$lhs.StartsWith("@")) -and (!$rhs.StartsWith("@")) `
            -and (!($lhs -eq 1)) -and (!($rhs -eq 1))) {
            if ($lhs -eq $rhs) {

                "$($proc.BaseName): $($match.value)"
            }
        }
    }
}

###########################
# Pass parameters by name #
###########################
Write-Host "`r`nParameters should be passed into procs by name:" -ForegroundColor Cyan

$procs = Get-ChildItem "C:\dev\project1\Stored Procedures\*.sql"

foreach ($proc in $procs)
{
    $match_info = Select-String -Path $proc.FullName -Pattern "exec[ute]*\s+[dbo.]*p_" -AllMatches

    if (!($match_info.Line | Select-String -Pattern "=" -SimpleMatch -Quiet)) {
        $proc.BaseName
    }
}
