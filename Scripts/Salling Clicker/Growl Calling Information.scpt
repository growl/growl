FasdUAS 1.101.10   ��   ��    k             l      �� ��   ��
	Salling Clicker script to log phone calls to Growl
	� 2004 Robert Leslie
	Inspired by George (Ty) Tempel's first implementation

	This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
	
	--Changes to work with growl: Jeremy Rossi
	
       	  j     �� 
�� 0 currentcalls currentCalls 
 J     ����   	     l     ������  ��        i        I      �������� 0 	connected  ��  ��    r         J     ����    o      ���� 0 currentcalls currentCalls      l     ������  ��        i        I      �������� 0 entered_proximity  ��  ��    r         J     ����    o      ���� 0 currentcalls currentCalls      l     ������  ��        i         I      �� !���� "0 phone_call_status_notification   !  "�� " o      ���� 0 
event_info  ��  ��     k     # #  $ % $ r      & ' & m      ( (  Growl Calling Information    ' o      ���� 0 appname appName %  ) * ) r     + , + m     - -  Call Status    , o      ���� $0 notificationname notificationName *  . / . r     0 1 0 J     2 2  3�� 3 o    	���� $0 notificationname notificationName��   1 o      ���� 
0 notifs   /  4 5 4 l   ������  ��   5  6 7 6 O      8 9 8 I   ���� :
�� .registernull��� ��� null��   : �� ; <
�� 
appl ; o    ���� 0 appname appName < �� = >
�� 
anot = o    ���� 
0 notifs   > �� ? @
�� 
dnot ? o    ���� 
0 notifs   @ �� A��
�� 
iapp A m     B B ! Bluetooth File Exchange.app   ��   9 m     C CLnull     ߀�� O��GrowlHelperApp.appL��� 7���` 
 � g @   )       �(�K� ��Ӏ�GRRR   alis    �  WideBoy                    ��.1H+   O��GrowlHelperApp.app                                              O���)��        ����  	                	Resources     ��.1      �)��     O�� O�� O�� +m �� ��  |  bWideBoy:Users:diggory:Library:PreferencePanes:Growl.prefPane:Contents:Resources:GrowlHelperApp.app  &  G r o w l H e l p e r A p p . a p p    W i d e B o y  ZUsers/diggory/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app  /    ��   7  D E D l  ! !������  ��   E  F G F w   ! H I H k   # J J  K L K l  # #�� M��   M @ :- "the_call_status" can have the following keyword values:    L  N O N l  # #�� P��   P D >- alerting/calling/connecting/holding/waiting/active/idle/busy    O  Q R Q r   # & S T S m   # $ U U       T o      ���� 0 call_status   R  V W V r   ' , X Y X n   ' * Z [ Z o   ( *���� 0 the_call_status   [ o   ' (���� 0 
event_info   Y o      ���� 0 event_call_status   W  \ ] \ Z   - � ^ _ `�� ^ =  - 0 a b a o   - .���� 0 event_call_status   b m   . /��
�� CSxxCSal _ r   3 6 c d c m   3 4 e e  alerting    d o      ���� 0 call_status   `  f g f =  9 < h i h o   9 :���� 0 event_call_status   i m   : ;��
�� CSxxCScl g  j k j r   ? D l m l m   ? B n n  calling    m o      ���� 0 call_status   k  o p o =  G L q r q o   G H���� 0 event_call_status   r m   H K��
�� CSxxCSct p  s t s r   O T u v u m   O R w w  
connecting    v o      ���� 0 call_status   t  x y x =  W \ z { z o   W X���� 0 event_call_status   { m   X [��
�� CSxxCShd y  | } | r   _ d ~  ~ m   _ b � �  holding     o      ���� 0 call_status   }  � � � =  g l � � � o   g h���� 0 event_call_status   � m   h k��
�� CSxxCSwt �  � � � r   o t � � � m   o r � �  waiting    � o      ���� 0 call_status   �  � � � =  w | � � � o   w x���� 0 event_call_status   � m   x {��
�� CSxxCSac �  � � � r    � � � � m    � � �  active    � o      ���� 0 call_status   �  � � � =  � � � � � o   � ����� 0 event_call_status   � m   � ���
�� CSxxCSid �  � � � r   � � � � � m   � � � � 
 idle    � o      ���� 0 call_status   �  � � � =  � � � � � o   � ����� 0 event_call_status   � m   � ���
�� CSxxCSbs �  ��� � r   � � � � � m   � � � � 
 busy    � o      ���� 0 call_status  ��  ��   ]  � � � l  � �������  ��   �  � � � l  � ��� ���   � > 8- "the_call_type" can have the following keyword values:    �  � � � l  � ��� ���   � &  - voice/data/fax/alternate voice    �  � � � r   � � � � � m   � � � �       � o      ���� 0 	call_type   �  � � � r   � � � � � n   � � � � � o   � ����� 0 the_call_type   � o   � ����� 0 
event_info   � o      ���� 0 event_call_type   �  � � � Z   � � � � ��� � =  � � � � � o   � ����� 0 event_call_type   � m   � ���
�� CTxxCTvc � r   � � � � � m   � � � �  voice    � o      ���� 0 	call_type   �  � � � =  � � � � � o   � ����� 0 event_call_type   � m   � ���
�� CTxxCTda �  � � � r   � � � � � m   � � � � 
 data    � o      ���� 0 	call_type   �  � � � =  � � � � � o   � ����� 0 event_call_type   � m   � ���
�� CTxxCTfx �  � � � r   � � � � � m   � � � � 	 fax    � o      ���� 0 	call_type   �  � � � =  � � � � � o   � ����� 0 event_call_type   � m   � ���
�� CTxxCTv2 �  ��� � r   � � � � � m   � � � �  alternate voice    � o      ���� 0 	call_type  ��  ��   �  � � � l  � �������  ��   �  � � � l  � ��� ���   � J D- "the_cid" is a numerical identifier represeting the call that this    �  � � � l  � ��� ���   � ; 5- event corresponds to (useful for tracking events in    �  � � � l  � ��� ���   �  - multi-party calls)    �  � � � r   �  � � � n   � � � � � o   � ����� 0 the_cid   � o   � ����� 0 
event_info   � o      ���� 0 event_call_id   �  � � � l ������  ��   �  � � � l �� ���   � 8 2- Additionally the "the_phone_number" string value    �  � � � l �� ���   � ; 5- is sometimes available (at least for "alerting" and    �  � � � l �� ���   �  - "calling")    �  � � � r   � � � m   � �       � o      ���� 0 event_caller_id   �  ��� � Q   � ��� � r  
 �  � n  
 o  ���� 0 the_phone_number   o  
���� 0 
event_info    o      ���� 0 event_caller_id   � R      ������
�� .ascrerr ****      � ****��  ��  ��  ��   IPnull      � �� !SEC Helper.app �0�L��utxt�T�� #� g (  ����    �T`��Q�<��ՐD JSCL  alis    �  WideBoy                    ��.1H+   !SEC Helper.app                                                  !üd�b        ����  	                	Resources     ��.1      �d�b     ! ! ! +m �� ��  |  hWideBoy:Users:diggory:Library:PreferencePanes:Salling Clicker.prefPane:Contents:Resources:SEC Helper.app    S E C   H e l p e r . a p p    W i d e B o y  `Users/diggory/Library/PreferencePanes/Salling Clicker.prefPane/Contents/Resources/SEC Helper.app  /    ��   G �� Z  �� E % J  #		 

 m    alerting    �� m  !  calling   ��   o  #$���� 0 call_status   k  (  Z  (=�� = (- o  ()���� 0 call_status   m  ),  alerting    r  05 m  03  incoming    o      ���� 0 	direction  ��   r  8= m  8;  outgoing    o      ���� 0 	direction    r  >C !  m  >A""      ! o      ���� 0 
thesummary 
theSummary #$# r  DL%&% I  DJ�'�~� 0 formatnumber formatNumber' (�}( o  EF�|�| 0 event_caller_id  �}  �~  & o      �{�{ 0 thelocation theLocation$ )*) r  MU+,+ I  MS�z-�y�z 0 	getperson 	getPerson- .�x. o  NO�w�w 0 event_caller_id  �x  �y  , o      �v�v 0 	theperson 	thePerson* /0/ Z  V�12�u31 = V[454 o  VW�t�t 0 	theperson 	thePerson5 m  WZ�s
�s 
msng2 r  ^e676 b  ^c898 o  ^_�r�r 0 
thesummary 
theSummary9 m  _b::  unknown   7 o      �q�q 0 
thesummary 
theSummary�u  3 w  h�;<; k  l�== >?> r  lu@A@ b  lsBCB o  lm�p�p 0 
thesummary 
theSummaryC n  mrDED 1  nr�o
�o 
pnamE o  mn�n�n 0 	theperson 	thePersonA o      �m�m 0 
thesummary 
theSummary? FGF r  v�HIH b  vJKJ m  vyLL  addressbook://   K n  y~MNM 1  z~�l
�l 
ID  N o  yz�k�k 0 	theperson 	thePersonI o      �j�j 0 theurl theURLG OPO l ���i�h�i  �h  P QRQ r  ��STS I  ���gU�f�g 0 getphone getPhoneU VWV o  ���e�e 0 event_caller_id  W X�dX o  ���c�c 0 	theperson 	thePerson�d  �f  T o      �b�b 0 thephone thePhoneR Y�aY Z  ��Z[�`�_Z > ��\]\ o  ���^�^ 0 thephone thePhone] m  ���]
�] 
msng[ r  ��^_^ b  ��`a` b  ��bcb b  ��ded b  ��fgf o  ���\�\ 0 thelocation theLocationg 1  ���[
�[ 
space m  ��hh  (   c n  ��iji 1  ���Z
�Z 
az18j o  ���Y�Y 0 thephone thePhonea m  ��kk  )   _ o      �X�X 0 thelocation theLocation�`  �_  �a  <�null      � ��  ^Address Book.app0�L��� 7���P    g    )       �(�K� ���p�adrb  alis    V  WideBoy                    ��.1H+    ^Address Book.app                                                 ����        ����  	                Applications    ��.1      ���      ^  %WideBoy:Applications:Address Book.app   "  A d d r e s s   B o o k . a p p    W i d e B o y  Applications/Address Book.app   / ��  0 lml l ���W�V�W  �V  m non r  ��pqp K  ��rr �Ust�U 0 thecid theCIDs o  ���T�T 0 event_call_id  t �Suv�S 0 thetype theTypeu o  ���R�R 0 	call_type  v �Qwx�Q 0 	thenumber 	theNumberw o  ���P�P 0 event_caller_id  x �Oyz�O 0 thedirection theDirectiony o  ���N�N 0 	direction  z �M{|�M 0 	starttime 	startTime{ I ���L�K�J
�L .misccurdldt    ��� null�K  �J  | �I}~�I 0 answeredtime answeredTime} m  ���H
�H 
msng~ �G��G 0 endtime endTime m  ���F
�F 
msng� �E���E 0 	theperson 	thePerson� o  ���D�D 0 
thesummary 
theSummary� �C��B�C 0 thelocation theLocation� o  ���A�A 0 thelocation theLocation�B  q o      �@�@ 0 thecall theCallo ��� s  ����� o  ���?�? 0 thecall theCall� n      ���  :  ��� o  ���>�> 0 currentcalls currentCalls� ��� l ���=�<�=  �<  � ��;� O  ���� I ��:�9�
�: .notifygrnull��� ��� null�9  � �8��
�8 
name� o  ���7�7 $0 notificationname notificationName� �6��
�6 
titl� b  ���� b  ����� o  ���5�5 0 	direction  � 1  ���4
�4 
spac� m  ��� 
 call   � �3��
�3 
appl� o  �2�2 0 appname appName� �1��0
�1 
desc� l ��/� c  ��� b  ��� b  ��� o  	�.�. 0 thelocation theLocation� o  	�-
�- 
ret � o  �,�, 0 
thesummary 
theSummary� m  �+
�+ 
TEXT�/  �0  � m  �� C�;  ��   k  �� ��� r  %��� I  !�*��)�* 0 getcallrecord getCallRecord� ��(� o  �'�' 0 event_call_id  �(  �)  � o      �&�& 0 thecall theCall� ��� r  &/��� I &+�%�$�#
�% .misccurdldt    ��� null�$  �#  � o      �"�" 0 thetime theTime� ��!� Z  0���� � = 05��� o  01�� 0 call_status  � m  14��  active   � k  8��� ��� Z  8U����� = 8C��� n  8?��� o  ;?�� 0 answeredtime answeredTime� o  8;�� 0 thecall theCall� m  ?B�
� 
msng� r  FQ��� o  FI�� 0 thetime theTime� n      ��� o  LP�� 0 answeredtime answeredTime� o  IL�� 0 thecall theCall�  �  � ��� O  V���� I Z����
� .notifygrnull��� ��� null�  � ���
� 
name� o  ^_�� $0 notificationname notificationName� ���
� 
titl� b  bq��� b  bm��� n  bi��� o  ei�� 0 thedirection theDirection� o  be�� 0 thecall theCall� 1  il�
� 
spac� m  mp��  answerd   � ���
� 
appl� o  rs�� 0 appname appName� ���

� 
desc� l v���	� c  v���� b  v���� b  v���� n  v}��� o  y}�� 0 thelocation theLocation� o  vy�� 0 thecall theCall� o  }��
� 
ret � n  ����� o  ���� 0 	theperson 	thePerson� o  ���� 0 thecall theCall� m  ���
� 
TEXT�	  �
  � m  VW C�  � ��� = ����� o  ���� 0 call_status  � m  ���� 
 idle   � ��� k  �	�� ��� r  ����� o  ��� �  0 thetime theTime� n      ��� o  ������ 0 endtime endTime� o  ������ 0 thecall theCall� ��� r  ����� I  ��������� 0 englishtime englishTime� ���� \  ����� l ������ n  ����� o  ������ 0 endtime endTime� o  ������ 0 thecall theCall��  � l ������ n  ����� o  ������ 0 answeredtime answeredTime� o  ������ 0 thecall theCall��  ��  ��  � o      ���� 0 theduration theDuration� ��� O  ���� I ������
�� .notifygrnull��� ��� null��  � ��� 
�� 
name� o  ������ $0 notificationname notificationName  ��
�� 
titl b  �� b  �� n  �� o  ������ 0 thedirection theDirection o  ������ 0 thecall theCall 1  ����
�� 
spac m  ��		  hungup    ��

�� 
appl
 o  ������ 0 appname appName ����
�� 
desc l ���� c  �� b  �� b  �� b  �� b  �� n  �� o  ������ 0 thelocation theLocation o  ������ 0 thecall theCall o  ����
�� 
ret  m  ��  Time:    1  ����
�� 
spac o  ������ 0 theduration theDuration m  ����
�� 
TEXT��  ��  � m  �� C� �� I  	������ $0 deletecallrecord deleteCallRecord �� o  ���� 0 event_call_id  ��  ��  ��  �  �   �!  ��     l     ������  ��    !  l     ������  ��  ! "#" l     ��$��  $ ( "-tell application "GrowlHelperApp"   # %&% l     ��'��  ' � �-notify with name notificationName title call_type application name appName description event_caller_id & ":  " & call_status with sticky   & ()( l     ��*��  *  	-end tell   ) +,+ l     ������  ��  , -.- l     ������  ��  . /0/ i    121 I      ��3���� 0 getcallrecord getCallRecord3 4��4 o      ���� 0 cid  ��  ��  2 k     255 676 X     '8��98 Z    ":;����: =   <=< n    >?> o    ���� 0 thecid theCID? o    ���� 0 acall aCall= o    ���� 0 cid  ; L    @@ o    ���� 0 acall aCall��  ��  �� 0 acall aCall9 o    ���� 0 currentcalls currentCalls7 ABA l  ( (������  ��  B C��C R   ( 2��D��
�� .ascrerr ****      � ****D b   * 1EFE b   * /GHG b   * -IJI m   * +KK   Missing call record for id   J 1   + ,��
�� 
spacH o   - .���� 0 cid  F m   / 0LL  .   ��  ��  0 MNM l     ������  ��  N OPO i    QRQ I      ��S���� $0 deletecallrecord deleteCallRecordS T��T o      ���� 0 cid  ��  ��  R k     8UU VWV r     XYX J     ����  Y o      ���� 0 newcalls newCallsW Z[Z X    0\��]\ Z    +^_����^ >   `a` n    bcb o    ���� 0 thecid theCIDc o    ���� 0 acall aCalla o    ���� 0 cid  _ s   ! 'ded n   ! $fgf 1   " $��
�� 
pcntg o   ! "���� 0 acall aCalle n      hih  ;   % &i o   $ %���� 0 newcalls newCalls��  ��  �� 0 acall aCall] o    ���� 0 currentcalls currentCalls[ jkj l  1 1������  ��  k l��l r   1 8mnm o   1 2���� 0 newcalls newCallsn o      ���� 0 currentcalls currentCalls��  P opo l     ������  ��  p qrq i    sts I      ��u���� 0 logcall logCallu v��v o      ���� 0 thecall theCall��  ��  t k    mww xyx r     z{z m     ||      { o      ���� 0 
thesummary 
theSummaryy }~} r    	� n    ��� o    ���� 0 thelog theLog� o    ���� 0 thecall theCall� o      ���� 0 thelog theLog~ ��� l  
 
������  ��  � ��� Z   
 N������ =  
 ��� n   
 ��� o    ���� 0 answeredtime answeredTime� o   
 ���� 0 thecall theCall� m    ��
�� 
msng� k    3�� ��� Z    ������� H    �� o    ���� (0 logunansweredcalls logUnansweredCalls� L    ����  ��  ��  � ��� l   ������  ��  � ���� Z    3������ =   #��� n    !��� o    !���� 0 thedirection theDirection� o    ���� 0 thecall theCall� m   ! "��  incoming   � r   & +��� b   & )��� m   & '��  missed   � 1   ' (��
�� 
spac� o      ���� 0 
thesummary 
theSummary��  � r   . 3��� b   . 1��� m   . /��  
unanswered   � 1   / 0��
�� 
spac� o      ���� 0 
thesummary 
theSummary��  ��  � r   6 N��� b   6 L��� b   6 J��� b   6 =��� b   6 ;��� b   6 9��� o   6 7���� 0 thelog theLog� o   7 8��
�� 
ret � m   9 :��  call duration   � 1   ; <��
�� 
spac� l 	 = I���� I   = I������� 0 englishtime englishTime� ���� \   > E��� l  > A���� n   > A��� o   ? A���� 0 endtime endTime� o   > ?�� 0 thecall theCall��  � l  A D��~� n   A D��� o   B D�}�} 0 answeredtime answeredTime� o   A B�|�| 0 thecall theCall�~  ��  ��  ��  � o   J K�{
�{ 
ret � o      �z�z 0 thelog theLog� ��� l  O O�y�x�y  �x  � ��� Z   O ������ =  O T��� n   O R��� o   P R�w�w 0 thetype theType� o   O P�v�v 0 thecall theCall� m   R S�� 	 fax   � r   W ^��� b   W \��� b   W Z��� o   W X�u�u 0 
thesummary 
theSummary� m   X Y�� 	 fax   � 1   Z [�t
�t 
spac� o      �s�s 0 
thesummary 
theSummary� ��� =  a h��� n   a d��� o   b d�r�r 0 thetype theType� o   a b�q�q 0 thecall theCall� m   d g�� 
 data   � ��p� r   k t��� b   k r��� b   k p��� o   k l�o�o 0 
thesummary 
theSummary� m   l o��  	data call   � 1   p q�n
�n 
spac� o      �m�m 0 
thesummary 
theSummary�p  � r   w ���� b   w ~��� b   w |��� o   w x�l�l 0 
thesummary 
theSummary� m   x {�� 
 call   � 1   | }�k
�k 
spac� o      �j�j 0 
thesummary 
theSummary� ��� l  � ��i�h�i  �h  � ��� Z   � ����g�� =  � ���� n   � ���� o   � ��f�f 0 thedirection theDirection� o   � ��e�e 0 thecall theCall� m   � ���  incoming   � r   � ���� b   � ���� b   � ���� o   � ��d�d 0 
thesummary 
theSummary� m   � ��� 
 from   � 1   � ��c
�c 
spac� o      �b�b 0 
thesummary 
theSummary�g  � r   � ���� b   � �   b   � � o   � ��a�a 0 
thesummary 
theSummary m   � �  to    1   � ��`
�` 
spac� o      �_�_ 0 
thesummary 
theSummary�  l  � ��^�]�^  �]    r   � �	
	 I   � ��\�[�\ 0 formatnumber formatNumber �Z n   � � o   � ��Y�Y 0 	thenumber 	theNumber o   � ��X�X 0 thecall theCall�Z  �[  
 o      �W�W 0 thelocation theLocation  r   � � I   � ��V�U�V 0 	getperson 	getPerson �T n   � � o   � ��S�S 0 	thenumber 	theNumber o   � ��R�R 0 thecall theCall�T  �U   o      �Q�Q 0 	theperson 	thePerson  r   � � m   � ��P
�P 
msng o      �O�O 0 theurl theURL  l  � ��N�M�N  �M    Z   � � �L�K I   � ��J!�I�J 0 shouldnotlog shouldNotLog! "�H" o   � ��G�G 0 	theperson 	thePerson�H  �I    L   � ��F�F  �L  �K   #$# l  � ��E�D�E  �D  $ %&% Z   �$'(�C)' =  � �*+* o   � ��B�B 0 	theperson 	thePerson+ m   � ��A
�A 
msng( r   � �,-, b   � �./. o   � ��@�@ 0 
thesummary 
theSummary/ m   � �00  unknown   - o      �?�? 0 
thesummary 
theSummary�C  ) w   �$1<1 k   �$22 343 r   � �565 b   � �787 o   � ��>�> 0 
thesummary 
theSummary8 n   � �9:9 1   � ��=
�= 
pnam: o   � ��<�< 0 	theperson 	thePerson6 o      �;�; 0 
thesummary 
theSummary4 ;<; r   � �=>= b   � �?@? m   � �AA  addressbook://   @ n   � �BCB 1   � ��:
�: 
ID  C o   � ��9�9 0 	theperson 	thePerson> o      �8�8 0 theurl theURL< DED l  � ��7�6�7  �6  E FGF r   �HIH I   ��5J�4�5 0 getphone getPhoneJ KLK n   � �MNM o   � ��3�3 0 	thenumber 	theNumberN o   � ��2�2 0 thecall theCallL O�1O o   � �0�0 0 	theperson 	thePerson�1  �4  I o      �/�/ 0 thephone thePhoneG P�.P Z  $QR�-�,Q > 
STS o  �+�+ 0 thephone thePhoneT m  	�*
�* 
msngR r   UVU b  WXW b  YZY b  [\[ b  ]^] o  �)�) 0 thelocation theLocation^ 1  �(
�( 
spac\ m  __  (   Z n  `a` 1  �'
�' 
az18a o  �&�& 0 thephone thePhoneX m  bb  )   V o      �%�% 0 thelocation theLocation�-  �,  �.  & cdc l %%�$�#�$  �#  d e�"e O %mfgf I +l�!� h
�! .corecrel****      � null�   h �ij
� 
kocli m  /2�
� 
wrevj �kl
� 
inshk n  5<mnm  ;  ;<n n 5;opo I  6;�q�� 0 getcalendar getCalendarq r�r o  67�� $0 logcalendartitle logCalendarTitle�  �  p  f  56l �s�
� 
prdts K  ?ftt �uv
� 
wr11u n BHwxw I  CH�y�� 0 
capitalize  y z�z o  CD�� 0 
thesummary 
theSummary�  �  x  f  BCv �{|
� 
wr14{ o  KL�� 0 thelocation theLocation| �}~
� 
wr1s} n  OT� o  PT�� 0 	starttime 	startTime� o  OP�� 0 thecall theCall~ ���
� 
wr5s� n  WZ��� o  XZ�� 0 endtime endTime� o  WX�
�
 0 thecall theCall� �	��
�	 
wr16� o  ]^�� 0 theurl theURL� ���
� 
wr12� o  ab�� 0 thelog theLog�  �  g m  %(���null     ߀��  ^iCal.app���P� �0�L��� 7��Հ  � g (   )       �(�K� ��ՠ #wrbt  alis    6  WideBoy                    ��.1H+    ^iCal.app                                                         ���        ����  	                Applications    ��.1      ��      ^  WideBoy:Applications:iCal.app     i C a l . a p p    W i d e B o y  Applications/iCal.app   / ��  �"  r ��� l     ���  �  � ��� i    ��� I      ���� 0 getcalendar getCalendar� �� � o      ���� 0 thetitle theTitle�   �  � O     1��� k    0�� ��� e    �� 6   ��� 2   ��
�� 
wres� =   ��� 1   	 ��
�� 
wr02� o    ���� 0 thetitle theTitle� ���� Z    0������ ?    ��� n    ��� 1    ��
�� 
leng� 1    ��
�� 
rslt� m    ����  � L     �� n    ��� 4   ���
�� 
cobj� m    ���� � 1    ��
�� 
rslt��  � L   # 0�� I  # /�����
�� .corecrel****      � null��  � ����
�� 
kocl� m   % &��
�� 
wres� �����
�� 
prdt� K   ' +�� �����
�� 
wr02� o   ( )���� 0 thetitle theTitle��  ��  ��  � m     �� ��� l     ������  ��  � ��� i     #��� I      ������� 0 	getperson 	getPerson� ���� o      ���� 0 	thenumber 	theNumber��  ��  � k     (�� ��� Q     %����� k    �� ��� O   ��� r    ��� I   �����
�� .seClLUabnull��� ��� obj � o    ���� 0 	thenumber 	theNumber��  � o      ���� 0 theuid theUID� m     I� ���� O   ��� L    �� 5    �����
�� 
azf4� o    ���� 0 theuid theUID
�� kfrmID  � m    <��  � R      ������
�� .ascrerr ****      � ****��  ��  ��  � ��� l  & &������  ��  � ���� L   & (�� m   & '��
�� 
msng��  � ��� l     ������  ��  � ��� i   $ '��� I      ������� 0 getphone getPhone� ��� o      ���� 0 	thenumber 	theNumber� ���� o      ���� 0 	theperson 	thePerson��  ��  � k     ]�� ��� r     ��� I     ������� 0 digitsof digitsOf� ���� o    ���� 0 	thenumber 	theNumber��  ��  � o      ���� 0 	thenumber 	theNumber� ��� l  	 	������  ��  � ��� Z   	 -������� F   	 ��� =  	 ��� n   	 ��� 1   
 ��
�� 
leng� o   	 
���� 0 	thenumber 	theNumber� m    ���� � =   ��� n    ��� l 	  ���� 4    ���
�� 
cha � m    ���� ��  � o    ���� 0 	thenumber 	theNumber� m    ��  1   � r    )��� n    '��� 7   '����
�� 
ctxt� m   ! #���� � m   $ &���� � o    ���� 0 	thenumber 	theNumber� o      ���� 0 	thenumber 	theNumber��  ��  � ��� l  . .������  ��  � ��� w   . Z�<� X   0 Z����� Z   B U������� E   B L� � n  B J I   C J������ 0 digitsof digitsOf �� n   C F 1   D F��
�� 
az17 o   C D���� 0 aphone aPhone��  ��    f   B C  o   J K���� 0 	thenumber 	theNumber� L   O Q o   O P���� 0 aphone aPhone��  ��  �� 0 aphone aPhone� n   3 6	 2  4 6��
�� 
az20	 o   3 4���� 0 	theperson 	thePerson� 

 l  [ [������  ��   �� L   [ ] m   [ \��
�� 
msng��  �  l     ������  ��    i   ( + I      ������ 0 ismember isMember  o      ���� 0 	theentity 	theEntity �� o      ���� 0 thegroup theGroup��  ��   k     6  w     3< X    3�� Z    .���� G    % !  =    "#" n    $%$ 1    ��
�� 
pcnt% o    ���� 0 agroup aGroup# o    ���� 0 thegroup theGroup! l 	  #&��& I    #��'���� 0 ismember isMember' ()( o    ���� 0 agroup aGroup) *��* o    ���� 0 thegroup theGroup��  ��  ��   L   ( *++ m   ( )��
�� boovtrue��  ��  �� 0 agroup aGroup n    ,-, 2   ��
�� 
azf5- o    ���� 0 	theentity 	theEntity ./. l  4 4������  ��  / 0��0 L   4 611 m   4 5��
�� boovfals��   232 l     ������  ��  3 454 i   , /676 I      ��8���� 0 shouldnotlog shouldNotLog8 9��9 o      ���� 0 	theperson 	thePerson��  ��  7 k     i:: ;<; Z     =>����= =    ?@? o     ���� 0 	theperson 	thePerson@ m    ��
�� 
msng> L    
AA >   	BCB o    ���� 0 loggroup logGroupC m    ��
�� 
msng��  ��  < DED l   �����  �  E FGF O    fHIH k    eJJ KLK Q    ;MN�~M Z    2OP�}�|O F    )QRQ >   STS o    �{�{ 0 
nologgroup 
noLogGroupT m    �z
�z 
msngR l 	  'U�yU n   'VWV I    '�xX�w�x 0 ismember isMemberX YZY o    �v�v 0 	theperson 	thePersonZ [�u[ 5    #�t\�s
�t 
azf5\ o     !�r�r 0 
nologgroup 
noLogGroup
�s kfrmname�u  �w  W  f    �y  P L   , .]] m   , -�q
�q boovtrue�}  �|  N R      �p�o�n
�p .ascrerr ****      � ****�o  �n  �~  L ^�m^ Q   < e_`�l_ Z   ? \ab�k�ja F   ? Scdc >  ? Befe o   ? @�i�i 0 loggroup logGroupf m   @ A�h
�h 
msngd l 	 E Qg�gg H   E Qhh n  E Piji I   F P�fk�e�f 0 ismember isMemberk lml o   F G�d�d 0 	theperson 	thePersonm n�cn 5   G L�bo�a
�b 
azf5o o   I J�`�` 0 loggroup logGroup
�a kfrmname�c  �e  j  f   E F�g  b L   V Xpp m   V W�_
�_ boovtrue�k  �j  ` R      �^�]�\
�^ .ascrerr ****      � ****�]  �\  �l  �m  I m    <G qrq l  g g�[�Z�[  �Z  r s�Ys L   g itt m   g h�X
�X boovfals�Y  5 uvu l     �W�V�W  �V  v wxw i   0 3yzy I      �U{�T�U 0 digitsof digitsOf{ |�S| o      �R�R 0 	thestring 	theString�S  �T  z k     1}} ~~ r     ��� m     ��  
0123456789   � o      �Q�Q 0 validdigits validDigits ��� r    ��� m    ��      � o      �P�P 0 	newstring 	newString� ��� X    .��O�� Z    )���N�M� E   ��� o    �L�L 0 validdigits validDigits� o    �K�K 0 adigit aDigit� r     %��� b     #��� o     !�J�J 0 	newstring 	newString� o   ! "�I�I 0 adigit aDigit� o      �H�H 0 	newstring 	newString�N  �M  �O 0 adigit aDigit� n    ��� 2   �G
�G 
cha � o    �F�F 0 	thestring 	theString� ��� l  / /�E�D�E  �D  � ��C� L   / 1�� o   / 0�B�B 0 	newstring 	newString�C  x ��� l     �A�@�A  �@  � ��� i   4 7��� I      �?��>�? 0 formatnumber formatNumber� ��=� o      �<�< 0 	thenumber 	theNumber�=  �>  � k     ��� ��� r     ��� I     �;��:�; 0 digitsof digitsOf� ��9� o    �8�8 0 	thenumber 	theNumber�9  �:  � o      �7�7 0 	thenumber 	theNumber� ��� l  	 	�6�5�6  �5  � ��� Z   	 �����4� =  	 ��� n   	 ��� 1   
 �3
�3 
leng� o   	 
�2�2 0 	thenumber 	theNumber� m    �1�1  � L    �� m    �0
�0 
msng� ��� F    &��� =   ��� n    ��� 1    �/
�/ 
leng� o    �.�. 0 	thenumber 	theNumber� m    �-�- � =   $��� n    "��� l 	  "��,� 4    "�+�
�+ 
cha � m     !�*�* �,  � o    �)�) 0 	thenumber 	theNumber� m   " #��  1   � ��� L   ) >�� b   ) =��� b   ) ,��� m   ) *��  +1   � 1   * +�(
�( 
spac� l 	 , <��'� I   , <�&��%�& 0 formatnumber formatNumber� ��$� n   - 8��� 7  . 8�#��
�# 
ctxt� m   2 4�"�" � m   5 7�!�! � o   - .� �  0 	thenumber 	theNumber�$  �%  �'  � ��� =  A F��� n   A D��� 1   B D�
� 
leng� o   A B�� 0 	thenumber 	theNumber� m   D E�� 
� ��� L   I h�� b   I g��� b   I V��� l 	 I T��� l  I T��� n   I T��� 7  J T���
� 
ctxt� m   N P�� � m   Q S�� � o   I J�� 0 	thenumber 	theNumber�  �  � 1   T U�
� 
spac� l 	 V f��� I   V f���� 0 formatnumber formatNumber� ��� n   W b��� 7  X b���
� 
ctxt� m   \ ^�� � m   _ a�� 
� o   W X�� 0 	thenumber 	theNumber�  �  �  � ��� =  k p��� n   k n��� 1   l n�
� 
leng� o   k l�� 0 	thenumber 	theNumber� m   n o�� � ��
� L   s ��� b   s ���� b   s ���� l 	 s ~��	� l  s ~��� n   s ~��� 7  t ~���
� 
ctxt� m   x z�� � m   { }�� � o   s t�� 0 	thenumber 	theNumber�  �	  � m   ~ ��  -   � l 	 � � �  l  � �� n   � � 7  � ��
� 
ctxt m   � �� �   m   � �����  o   � ����� 0 	thenumber 	theNumber�  �  �
  �4  �  l  � �������  ��   �� L   � �		 o   � ����� 0 	thenumber 	theNumber��  � 

 l     ������  ��    i   8 ; I      ������ 0 englishcount englishCount  o      ���� 0 howmany howMany �� o      ���� 0 
unitstring 
unitString��  ��   k       r     	 c      b      b      o     ���� 0 howmany howMany 1    ��
�� 
spac o    ���� 0 
unitstring 
unitString m    ��
�� 
TEXT o      ���� 0 	thestring 	theString   Z   
 !"����! >   
 #$# o   
 ���� 0 howmany howMany$ m    ���� " r    %&% b    '(' o    ���� 0 	thestring 	theString( m    ))  s   & o      ���� 0 	thestring 	theString��  ��    *+* l   ������  ��  + ,��, L    -- o    ���� 0 	thestring 	theString��   ./. l     ������  ��  / 010 i   < ?232 I      ��4���� 0 englishtime englishTime4 5��5 o      ���� 0 
numseconds 
numSeconds��  ��  3 k     �66 787 r     9:9 J     ����  : o      ���� 0 theelements theElements8 ;<; Z    !=>����= @    ?@? o    ���� 0 
numseconds 
numSeconds@ 1    ��
�� 
hour> k    AA BCB s    DED I    ��F���� 0 englishcount englishCountF GHG _    IJI o    ���� 0 
numseconds 
numSecondsJ 1    ��
�� 
hourH K��K m    LL 
 hour   ��  ��  E n      MNM  ;    N o    ���� 0 theelements theElementsC O��O r    PQP `    RSR o    ���� 0 
numseconds 
numSecondsS 1    ��
�� 
hourQ o      ���� 0 
numseconds 
numSeconds��  ��  ��  < TUT l  " "������  ��  U VWV Z   " >XY����X @   " %Z[Z o   " #���� 0 
numseconds 
numSeconds[ 1   # $��
�� 
min Y k   ( :\\ ]^] s   ( 4_`_ I   ( 1��a���� 0 englishcount englishCounta bcb _   ) ,ded o   ) *���� 0 
numseconds 
numSecondse 1   * +��
�� 
min c f��f m   , -gg  minute   ��  ��  ` n      hih  ;   2 3i o   1 2���� 0 theelements theElements^ j��j r   5 :klk `   5 8mnm o   5 6���� 0 
numseconds 
numSecondsn 1   6 7��
�� 
min l o      ���� 0 
numseconds 
numSeconds��  ��  ��  W opo l  ? ?������  ��  p qrq Z   ? ]st����s G   ? Luvu ?   ? Bwxw o   ? @���� 0 
numseconds 
numSecondsx m   @ A����  v =  E Jyzy n   E H{|{ l 	 F H}��} 1   F H��
�� 
leng��  | o   E F���� 0 theelements theElementsz m   H I����  t s   O Y~~ I   O V������� 0 englishcount englishCount� ��� o   P Q���� 0 
numseconds 
numSeconds� ���� m   Q R��  second   ��  ��   n      ���  ;   W X� o   V W���� 0 theelements theElements��  ��  r ��� l  ^ ^������  ��  � ���� Z   ^ ������ =   ^ c��� n   ^ a��� 1   _ a��
�� 
leng� o   ^ _���� 0 theelements theElements� m   a b���� � L   f }�� b   f |��� b   f w��� b   f u��� b   f s��� b   f n��� b   f l��� n   f j��� l 	 g j���� 4   g j���
�� 
cobj� m   h i���� ��  � o   f g���� 0 theelements theElements� m   j k��  ,   � 1   l m��
�� 
spac� n   n r��� l 	 o r���� 4   o r���
�� 
cobj� m   p q���� ��  � o   n o���� 0 theelements theElements� m   s t��  , and   � 1   u v��
�� 
spac� n   w {��� l 	 x {���� 4   x {���
�� 
cobj� m   y z���� ��  � o   w x���� 0 theelements theElements� ��� =   � ���� n   � ���� 1   � ���
�� 
leng� o   � ����� 0 theelements theElements� m   � ����� � ���� L   � ��� b   � ���� b   � ���� b   � ���� b   � ���� n   � ���� l 	 � ����� 4   � ����
�� 
cobj� m   � ����� ��  � o   � ����� 0 theelements theElements� 1   � ���
�� 
spac� m   � ��� 	 and   � 1   � ���
�� 
spac� n   � ���� l 	 � ����� 4   � ����
�� 
cobj� m   � ����� ��  � o   � ����� 0 theelements theElements��  � L   � ��� n   � ���� l 	 � ����� 4   � ����
�� 
cobj� m   � ����� ��  � o   � ����� 0 theelements theElements��  1 ��� l     ������  ��  � ��� i   @ C��� I      ������� 0 
capitalize  � ���� o      ���� 0 	thestring 	theString��  ��  � k     O�� ��� Z     L������� ?     ��� n     ��� 1    ��
�� 
leng� o     �� 0 	thestring 	theString� m    �~�~  � k    H�� ��� r    ��� I   �}��|
�} .sysoctonshor       TEXT� l   ��{� n    ��� 4   	 �z�
�z 
cha � m   
 �y�y � o    	�x�x 0 	thestring 	theString�{  �|  � o      �w�w 	0 ascii  � ��� l   �v�u�v  �u  � ��t� Z    H���s�r� F    &��� @    ��� l 	  ��q� o    �p�p 	0 ascii  �q  � l   ��o� I   �n��m
�n .sysoctonshor       TEXT� m    ��  a   �m  �o  � B    $��� l 	  ��l� o    �k�k 	0 ascii  �l  � l   #��j� I   #�i��h
�i .sysoctonshor       TEXT� m    ��  z   �h  �j  � r   ) D��� b   ) B��� l 	 ) :��g� l  ) :��f� I  ) :�e��d
�e .sysontocTEXT       shor� l  ) 6 �c  [   ) 6 \   ) 0 o   ) *�b�b 	0 ascii   l  * /�a I  * /�`�_
�` .sysoctonshor       TEXT m   * +  a   �_  �a   l  0 5�^ I  0 5�]	�\
�] .sysoctonshor       TEXT	 m   0 1

  A   �\  �^  �c  �d  �f  �g  � l  : A�[ c   : A n   : ? 1   = ?�Z
�Z 
rest n   : = 2  ; =�Y
�Y 
cha  o   : ;�X�X 0 	thestring 	theString m   ? @�W
�W 
TEXT�[  � o      �V�V 0 	thestring 	theString�s  �r  �t  ��  ��  �  l  M M�U�T�U  �T   �S L   M O o   M N�R�R 0 	thestring 	theString�S  � �Q l     �P�O�P  �O  �Q       �N !"#$%&'(�N   �M�L�K�J�I�H�G�F�E�D�C�B�A�@�?�>�=�M 0 currentcalls currentCalls�L 0 	connected  �K 0 entered_proximity  �J "0 phone_call_status_notification  �I 0 getcallrecord getCallRecord�H $0 deletecallrecord deleteCallRecord�G 0 logcall logCall�F 0 getcalendar getCalendar�E 0 	getperson 	getPerson�D 0 getphone getPhone�C 0 ismember isMember�B 0 shouldnotlog shouldNotLog�A 0 digitsof digitsOf�@ 0 formatnumber formatNumber�? 0 englishcount englishCount�> 0 englishtime englishTime�= 0 
capitalize   �<�;�<  �;   �: �9�8)*�7�: 0 	connected  �9  �8  )  *  �7 	jvEc    �6 �5�4+,�3�6 0 entered_proximity  �5  �4  +  ,  �3 	jvEc    �2  �1�0-.�/�2 "0 phone_call_status_notification  �1 �./�. /  �-�- 0 
event_info  �0  - �,�+�*�)�(�'�&�%�$�#�"�!� �������, 0 
event_info  �+ 0 appname appName�* $0 notificationname notificationName�) 
0 notifs  �( 0 call_status  �' 0 event_call_status  �& 0 	call_type  �% 0 event_call_type  �$ 0 event_call_id  �# 0 event_caller_id  �" 0 	direction  �! 0 
thesummary 
theSummary�  0 thelocation theLocation� 0 	theperson 	thePerson� 0 theurl theURL� 0 thephone thePhone� 0 thecall theCall� 0 thetime theTime� 0 theduration theDuration. Y ( - C���� B�� I U�� e� n� w� �� �� �� �� � ��
�	 �� �� �� �� ����"�� ��:<��L������h��k������������������������������������������	��
� 
appl
� 
anot
� 
dnot
� 
iapp� 
� .registernull��� ��� null� 0 the_call_status  
� CSxxCSal
� CSxxCScl
� CSxxCSct
� CSxxCShd
� CSxxCSwt
� CSxxCSac
� CSxxCSid
� CSxxCSbs�
 0 the_call_type  
�	 CTxxCTvc
� CTxxCTda
� CTxxCTfx
� CTxxCTv2� 0 the_cid  � 0 the_phone_number  �  �  � 0 formatnumber formatNumber�  0 	getperson 	getPerson
�� 
msng
�� 
pnam
�� 
ID  �� 0 getphone getPhone
�� 
spac
�� 
az18�� 0 thecid theCID�� 0 thetype theType�� 0 	thenumber 	theNumber�� 0 thedirection theDirection�� 0 	starttime 	startTime
�� .misccurdldt    ��� null�� 0 answeredtime answeredTime�� 0 endtime endTime�� 0 	theperson 	thePerson�� 0 thelocation theLocation�� 
�� 
name
�� 
titl
�� 
desc
�� 
ret 
�� 
TEXT
�� .notifygrnull��� ��� null�� 0 getcallrecord getCallRecord�� 0 englishtime englishTime�� $0 deletecallrecord deleteCallRecord�/�E�O�E�O�kvE�O� *������ 	UO�Z�E�O��,E�O��  �E�Y q��  
a E�Y c�a   
a E�Y S�a   
a E�Y C�a   
a E�Y 3�a   
a E�Y #�a   
a E�Y �a   
a E�Y hOa E�O�a ,E�O�a   
a  E�Y 3�a !  
a "E�Y #�a #  
a $E�Y �a %  
a &E�Y hO�a ',E�Oa (E�O �a ),E�W X * +hOa ,a -lv� ��a .  
a /E�Y a 0E�Oa 1E�O*�k+ 2E�O*�k+ 3E�O�a 4  �a 5%E�Y Ga 6Z��a 7,%E�Oa 8�a 9,%E�O*��l+ :E�O�a 4 �_ ;%a <%�a =,%a >%E�Y hOa ?�a @�a A�a B�a C*j Da Ea 4a Fa 4a G�a H�a IE^ O] b   5GO� '*a J�a K�_ ;%a L%�a M�_ N%�%a O&� PUY �*�k+ QE^ O*j DE^ O�a R  _] a E,a 4  ] ] a E,FY hO� 9*a J�a K] a B,_ ;%a S%�a M] a H,_ N%] a G,%a O&� PUY z�a T  q] ] a F,FO*] a F,] a E,k+ UE^ O� =*a J�a K] a B,_ ;%a V%�a M] a H,_ N%a W%_ ;%] %a O&� PUO*�k+ XY h ��2����01���� 0 getcallrecord getCallRecord�� ��2�� 2  ���� 0 cid  ��  0 ������ 0 cid  �� 0 acall aCall1 ��������K��L
�� 
kocl
�� 
cobj
�� .corecnte****       ****�� 0 thecid theCID
�� 
spac�� 3 &b   [��l kh ��,�  �Y h[OY��O)j��%�%�% ��R����34���� $0 deletecallrecord deleteCallRecord�� ��5�� 5  ���� 0 cid  ��  3 �������� 0 cid  �� 0 newcalls newCalls�� 0 acall aCall4 ����������
�� 
kocl
�� 
cobj
�� .corecnte****       ****�� 0 thecid theCID
�� 
pcnt�� 9jvE�O *b   [��l kh ��,� ��,�6GY h[OY��O�Ec    ��t����67���� 0 logcall logCall�� ��8�� 8  ���� 0 thecall theCall��  6 	�������������������� 0 thecall theCall�� 0 
thesummary 
theSummary�� 0 thelog theLog�� (0 logunansweredcalls logUnansweredCalls�� 0 thelocation theLocation�� 0 	theperson 	thePerson�� 0 theurl theURL�� 0 thephone thePhone�� $0 logcalendartitle logCalendarTitle7 4|�������������������������������������0<��A����_��b����������������������������������� 0 thelog theLog�� 0 answeredtime answeredTime
�� 
msng�� 0 thedirection theDirection
�� 
spac
�� 
ret �� 0 endtime endTime�� 0 englishtime englishTime�� 0 thetype theType�� 0 	thenumber 	theNumber�� 0 formatnumber formatNumber�� 0 	getperson 	getPerson�� 0 shouldnotlog shouldNotLog
�� 
pnam
�� 
ID  �� 0 getphone getPhone
�� 
az18
�� 
kocl
�� 
wrev
�� 
insh�� 0 getcalendar getCalendar
�� 
prdt
�� 
wr11�� 0 
capitalize  
�� 
wr14
�� 
wr1s�� 0 	starttime 	startTime
�� 
wr5s
�� 
wr16
�� 
wr12�� �� 
�� .corecrel****      � null��n�E�O��,E�O��,�  &� hY hO��,�  
��%E�Y ��%E�Y ��%�%�%*��,��,k+ %�%E�O��,�  ��%�%E�Y !��,a   �a %�%E�Y �a %�%E�O��,a   �a %�%E�Y �a %�%E�O*�a ,k+ E�O*�a ,k+ E�O�E�O*�k+  hY hO��  �a %E�Y Ga Z��a ,%E�Oa �a ,%E�O*�a ,�l+ E�O�� ��%a  %�a !,%a "%E�Y hOa # C*a $a %a &)�k+ '6a (a ))�k+ *a +�a ,�a -,a .��,a /�a 0�a 1a 2 3U �������9:���� 0 getcalendar getCalendar�� ��;�� ;  ���� 0 thetitle theTitle��  9 ���� 0 thetitle theTitle: ���<����������������
�� 
wres<  
�� 
wr02
�� 
rslt
�� 
leng
�� 
cobj
�� 
kocl
�� 
prdt�� 
�� .corecrel****      � null�� 2� .*�-�[�,\Z�81EO��,j ��k/EY *����l� 
U  �������=>���� 0 	getperson 	getPerson�� ��?�� ?  ���� 0 	thenumber 	theNumber��  = ������ 0 	thenumber 	theNumber�� 0 theuid theUID>  I��<������~�}
�� .seClLUabnull��� ��� obj 
�� 
azf4
�� kfrmID  �  �~  
�} 
msng�� ) � 	�j E�UO� 	*��0EUW X  hO�! �|��{�z@A�y�| 0 getphone getPhone�{ �xB�x B  �w�v�w 0 	thenumber 	theNumber�v 0 	theperson 	thePerson�z  @ �u�t�s�u 0 	thenumber 	theNumber�t 0 	theperson 	thePerson�s 0 aphone aPhoneA �r�q�p�o��n�m<�l�k�j�i�h�g�r 0 digitsof digitsOf
�q 
leng�p 
�o 
cha 
�n 
bool
�m 
ctxt
�l 
az20
�k 
kocl
�j 
cobj
�i .corecnte****       ****
�h 
az17
�g 
msng�y ^*�k+  E�O��,� 	 
��k/� �& �[�\[Zl\Z�2E�Y hO�Z )��-[��l kh )��,k+  � �Y h[OY��O�" �f�e�dCD�c�f 0 ismember isMember�e �bE�b E  �a�`�a 0 	theentity 	theEntity�` 0 thegroup theGroup�d  C �_�^�]�_ 0 	theentity 	theEntity�^ 0 thegroup theGroup�] 0 agroup aGroupD <�\�[�Z�Y�X�W�V
�\ 
azf5
�[ 
kocl
�Z 
cobj
�Y .corecnte****       ****
�X 
pcnt�W 0 ismember isMember
�V 
bool�c 7�Z 0��-[��l kh ��,� 
 *��l+ �& eY h[OY��Of# �U7�T�SFG�R�U 0 shouldnotlog shouldNotLog�T �QH�Q H  �P�P 0 	theperson 	thePerson�S  F �O�N�M�O 0 	theperson 	thePerson�N 0 loggroup logGroup�M 0 
nologgroup 
noLogGroupG �L<�K�J�I�H�G�F
�L 
msng
�K 
azf5
�J kfrmname�I 0 ismember isMember
�H 
bool�G  �F  �R j��  	��Y hO� T !��	 )�*��0l+ �& eY hW X  hO "��	 )�*��0l+ �& eY hW X  hUOf$ �Ez�D�CIJ�B�E 0 digitsof digitsOf�D �AK�A K  �@�@ 0 	thestring 	theString�C  I �?�>�=�<�? 0 	thestring 	theString�> 0 validdigits validDigits�= 0 	newstring 	newString�< 0 adigit aDigitJ ���;�:�9�8
�; 
cha 
�: 
kocl
�9 
cobj
�8 .corecnte****       ****�B 2�E�O�E�O %��-[��l kh �� 
��%E�Y h[OY��O�% �7��6�5LM�4�7 0 formatnumber formatNumber�6 �3N�3 N  �2�2 0 	thenumber 	theNumber�5  L �1�1 0 	thenumber 	theNumberM �0�/�.�-�,��+��*�)�(�'�&�%��0 0 digitsof digitsOf
�/ 
leng
�. 
msng�- 
�, 
cha 
�+ 
bool
�* 
spac
�) 
ctxt�( 0 formatnumber formatNumber�' 
�& �% �4 �*�k+  E�O��,j  �Y }��,� 	 
��k/� �& ��%*�[�\[Zl\Z�2k+ 
%Y R��,�  $�[�\[Zk\Zm2�%*�[�\[Z�\Z�2k+ 
%Y (��,�  �[�\[Zk\Zm2�%�[�\[Z�\Z�2%Y hO�& �$�#�"OP�!�$ 0 englishcount englishCount�# � Q�  Q  ��� 0 howmany howMany� 0 
unitstring 
unitString�"  O ���� 0 howmany howMany� 0 
unitstring 
unitString� 0 	thestring 	theStringP ��)
� 
spac
� 
TEXT�! ��%�%�&E�O�k 
��%E�Y hO�' �3��RS�� 0 englishtime englishTime� �T� T  �� 0 
numseconds 
numSeconds�  R ��� 0 
numseconds 
numSeconds� 0 theelements theElementsS �L��g������
��
� 
hour� 0 englishcount englishCount
� 
min 
� 
leng
� 
bool
� 
cobj
�
 
spac� �jvE�O�� *��"�l+ �6GO��#E�Y hO�� *��"�l+ �6GO��#E�Y hO�j
 	��,j �& *��l+ �6GY hO��,m  ��k/�%�%��l/%�%�%��m/%Y #��,l  ��k/�%�%�%��l/%Y ��k/E( �	���UV��	 0 
capitalize  � �W� W  �� 0 	thestring 	theString�  U ��� 0 	thestring 	theString� 	0 ascii  V �� ������
������
� 
leng
�  
cha 
�� .sysoctonshor       TEXT
�� 
bool
�� .sysontocTEXT       shor
�� 
rest
�� 
TEXT� P��,j E��k/j E�O��j 	 ��j �&  ��j �j j ��-�,�&%E�Y hY hO�ascr  ��ޭ