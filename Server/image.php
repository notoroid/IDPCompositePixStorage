<?php
define('BASE_DIRECTORY', "./images/" );

$us_path = $_POST['path'];
$result = preg_match('/(\.\.\/|\/|\.\.\\\\)/', $us_path) ? TRUE : FALSE;
$s_path = $result == TRUE ? (BASE_DIRECTORY . $us_path) : "";

header('Content-type: image/jpeg');
readfile(BASE_DIRECTORY . $us_path );

?>