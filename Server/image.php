<?php
define('BASE_DIRECTORY', "./" );

$us_path = $_REQUEST['path'];
$result = preg_match('/(\.\.\/|\/|\.\.\\\\)/', $us_path) ? TRUE : FALSE;
$s_path = $result == TRUE ? (BASE_DIRECTORY . $us_path) : "";

$pathInformation = pathinfo($s_path);

// アクセス可能なMINEを設定
$supportMINEs = array('gif'=>'image/gif','jpg'=>'image/jpeg','jpeg'=>'image/jpeg','png'=>'image/png','pdf'=>'application/pdf');

$content_type = $supportMINEs[$pathInformation['extension']];

header('Content-type: ' . $content_type );
readfile(/*$s_path*/ BASE_DIRECTORY . $us_path );

?>