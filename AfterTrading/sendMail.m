function [ ] = sendMail(to, subject, message )
addr='trader@jasperam.com';
passw='jasperam@123';
setpref('Internet','E_mail',addr);
setpref('Internet','SMTP_Server','mail.jasperam.com');
setpref('Internet','SMTP_Username',addr);
setpref('Internet','SMTP_Password',passw);
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
sendmail(to, subject, message);
end

