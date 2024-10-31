<?php

$dsn = "mysql:dbname=luccie_teamawesome;host=127.0.0.1";
$user = "luccie_tauser";
$password = "M0nst3r";

try
{
    $sql = new PDO($dsn, $user, $password);
}
catch(PDOException $e)
{
    die('Unable to connect to the SQL database');
}
?>
