% Ableitung der Rotationskomponente kinematischen ZB nach den Gelenkwinkeln
% Bezeichnungen: Rotatorischer Teil der ...
% * Jacobi-Matrix der inversen Kinematik, 
% * geometrische Matrix der inversen Kinematik
% (ist in der Literatur wenig gebräuchlich)
% 
% Variante 1:
% * Absolute Rotation ausgedrückt in XYZ-Euler-Winkeln
% * Rotationsfehler ausgedrückt in XYZ-Euler-Winkeln
% 
% Eingabe:
% q [Nx1]
%   Alle Gelenkwinkel aller serieller Beinketten der PKM
% qD [Nx1]
%   Geschwindigkeit aller Gelenkwinkel aller serieller Beinketten der PKM
% xE [6x1]
%   Endeffektorpose des Roboters bezüglich des Basis-KS
% xDE [6x1]
%   Zeitableitung der Endeffektorpose des Roboters bezüglich des Basis-KS
% 
% Ausgabe:
% PhiD_q_red
%   Ableitung der kinematischen Zwangsbedingungen nach allen Gelenkwinkeln
%   Rotatorischer Teil
%   Reduzierte Zeilen: Die Reduktion folgt aus der Klassenvariablen I_EE
% PhiD_q [3xN]
%   Siehe vorher. Hier alle Zeilen der Zwangsbedingungen

% Siehe auch: constr1grad_rq.m

% Moritz Schappler, moritz.schappler@imes.uni-hannover.de, 2018-10
% (C) Institut für Mechatronische Systeme, Universität Hannover

function [Phipq_red, Phipq] = constr1gradD_rq(Rob, q, qD, xE, xDE)

%% Initialisierung
assert(isreal(q) && all(size(q) == [Rob.NJ 1]), ...
  'ParRob/constr1gradD_rq: q muss %dx1 sein', Rob.NJ);
assert(isreal(qD) && all(size(qD) == [Rob.NJ 1]), ...
  'ParRob/constr1gradD_rq: qD muss %dx1 sein', Rob.NJ);
assert(isreal(xE) && all(size(xE) == [6 1]), ...
  'ParRob/constr1gradD_rq: xE muss 6x1 sein');
assert(isreal(xDE) && all(size(xDE) == [6 1]), ...
  'ParRob/constr1gradD_rq: xDE muss 6x1 sein');

NLEG = Rob.NLEG;
NJ = Rob.NJ;

%% Initialisierung mit Fallunterscheidung für symbolische Eingabe
% Endergebnis, siehe Gl. (B.30)

if ~Rob.issym
  Phipq = zeros(3*NLEG,NJ);
  Phipq_red = zeros(length(Rob.I_constr_r_red),NJ);
else
  Phipq = sym('phi', [3*NLEG,NJ]);
  Phipq(:)=0;
  Phipq_red = sym('phi', [length(Rob.I_constr_r_red),NJ]);
  Phipq_red(:)=0;
end
%% Berechnung
R_P_E = Rob.T_P_E(1:3,1:3);   % homogeneous transformation zwischen endeffektor Koordinate System und Platform Koordinate System 
R_0_E_x = eul2r(xE(4:6), Rob.phiconv_W_E);  % euler winkel im rotation matrix convertierien
omega_0_Ex = euljac(xE(4:6), Rob.phiconv_W_E) * xDE(4:6);
R_Bi_P  = eye(3,3);

K1 = 1;
for iLeg = 1:NLEG
  % Anteil der ZB-Gleichung der Gelenkkette
  IJ_i = Rob.I1J_LEG(iLeg):Rob.I2J_LEG(iLeg);
  qi = q(IJ_i); % coordinates of the joint coordinate for the serial chain
  qDi= qD(IJ_i); % velocity of the joint coordinate for the serial chain 
  
  phi_0_Ai = Rob.Leg(iLeg).phi_W_0; % Rotation zum Basis-KS der Beinkette
  R_0_0i = eul2r(phi_0_Ai, Rob.Leg(iLeg).phiconv_W_0);
  
  % Kinematik, Definitionen
  T_0i_Bi = Rob.Leg(iLeg).fkineEE(qi);
  R_0i_E_q = T_0i_Bi(1:3,1:3) * R_P_E;
  R_0_E_q = R_0_0i * R_0i_E_q;
  
  % Rotationsmatrix des Orientierungsfehlers
  R_0x_0q = R_0_E_q * R_0_E_x';
  
  % Ableitungen der Rotationsmatrizen berechnen
  omega_0i_Bi = Rob.Leg(iLeg).jacobiw(qi)* qDi;
  RD_0i_Bi = T_0i_Bi(1:3,1:3) * skew(omega_0i_Bi) ;
  RD_0_E_q = R_0_0i * RD_0i_Bi * R_Bi_P * R_P_E ;

  RD_0_E_x =  R_0_E_x * skew(omega_0_Ex);
  RD_0x_0q = (R_0_E_q * RD_0_E_x') + (RD_0_E_q * R_0_E_x'); % Produktregel
  
  % Term III aus Gl. (B.31): Ableitung der Rotationsmatrix R_0_E nach q
  % Berücksichtigung der zusätzlichen Transformation RS.T_N_E: Gl. (C.7)
  % (jacobiR berücksichtigt diese Rotation nicht; ist definiert zum letzten
  % Körper-KS N der seriellen Kette. Hier werden dadurch direkt zwei
  % Transformationen berücksichtigt: N->Bi->E
  % RS.TNE bezieht sich auf den "Endeffektor" der Beinkette, der "Bi" ist.
  % Gl. (B.33)
  R_Ni_E = Rob.Leg(iLeg).T_N_E(1:3,1:3) * R_P_E;  % RS.TNE bezieht sich auf den "Endeffektor" der Beinkette
  b11=R_Ni_E(1,1);b12=R_Ni_E(1,2);b13=R_Ni_E(1,3);
  b21=R_Ni_E(2,1);b22=R_Ni_E(2,2);b23=R_Ni_E(2,3);
  b31=R_Ni_E(3,1);b32=R_Ni_E(3,2);b33=R_Ni_E(3,3);
  dPidRb1 = [b11 0 0 b21 0 0 b31 0 0; 0 b11 0 0 b21 0 0 b31 0; 0 0 b11 0 0 b21 0 0 b31; b12 0 0 b22 0 0 b32 0 0; 0 b12 0 0 b22 0 0 b32 0; 0 0 b12 0 0 b22 0 0 b32; b13 0 0 b23 0 0 b33 0 0; 0 b13 0 0 b23 0 0 b33 0; 0 0 b13 0 0 b23 0 0 b33;];% q
  dRb_0iN_dq = Rob.Leg(iLeg).jacobiR(qi);% Jacobi-Matrix bzgl der Rotationsmatrix des Endeffektors J
  
  dDRb_0iN_dq = Rob.Leg(iLeg).jacobiRD(qi,qDi);
  dRb_0iE_dq = dPidRb1 * dRb_0iN_dq;
  dDRb_0iE_dq = dPidRb1 * dDRb_0iN_dq;
  
 % dRb_0iN_dqw = Rob.Leg(iLeg).jacobiw(qs) % Rotatorischer Teil der geometrischen Jacobi-Matrix  JR
 % dRb_0iE_dqw = dPidRb1 * dRb_0iN_dqw;
  
  % Bezug auf Basis-KS der PKM und nicht Basis des seriellen Roboters
  % Matrix-Produkt aus rmatvecprod_diff_rmatvec2_matlab.m, siehe Gl. (A.13)
   % CALCULATING THE VALUE OF 0Rdot E
   % dPidRbD2 is the differntiation of the third term 
   
   
  %%
  a11=R_0_0i(1,1);a12=R_0_0i(1,2);a13=R_0_0i(1,3);
  a21=R_0_0i(2,1);a22=R_0_0i(2,2);a23=R_0_0i(2,3);
  a31=R_0_0i(3,1);a32=R_0_0i(3,2);a33=R_0_0i(3,3);
  dPidRb2 = [a11 a12 a13 0 0 0 0 0 0; a21 a22 a23 0 0 0 0 0 0; a31 a32 a33 0 0 0 0 0 0; 0 0 0 a11 a12 a13 0 0 0; 0 0 0 a21 a22 a23 0 0 0; 0 0 0 a31 a32 a33 0 0 0; 0 0 0 0 0 0 a11 a12 a13; 0 0 0 0 0 0 a21 a22 a23; 0 0 0 0 0 0 a31 a32 a33;];
 %%
  dRb_0E_dq = dPidRb2 * dRb_0iE_dq;   % 1/dq * dre
  dDRb_0E_dq = dPidRb2 * dDRb_0iE_dq ;
  % Term II aus Gl. (B.31): Innere Ableitung des Matrix-Produktes
  % Die Matrix R_0_E_x wird transponiert eingesetzt.
  % aus rmatvecprod_diff_rmatvec1_matlab.m
  % dPidRb1 is the value for the 0Rd T 
  e11=R_0_E_x(1,1);e12=R_0_E_x(2,1);e13=R_0_E_x(3,1);
  e21=R_0_E_x(1,2);e22=R_0_E_x(2,2);e23=R_0_E_x(3,2);
  e31=R_0_E_x(1,3);e32=R_0_E_x(2,3);e33=R_0_E_x(3,3);
  dPidRb1 = [e11 0 0 e21 0 0 e31 0 0; 0 e11 0 0 e21 0 0 e31 0; 0 0 e11 0 0 e21 0 0 e31; e12 0 0 e22 0 0 e32 0 0; 0 e12 0 0 e22 0 0 e32 0; 0 0 e12 0 0 e22 0 0 e32; e13 0 0 e23 0 0 e33 0 0; 0 e13 0 0 e23 0 0 e33 0; 0 0 e13 0 0 e23 0 0 e33;];
 %% Calculatng the ableitung with respect to the time for the above term und die Ableitung von II term
 % the dPidRbD1 term is the value of the 0Rddot D  T
  
  c11=RD_0_E_x(1,1);c12=RD_0_E_x(2,1);c13=RD_0_E_x(3,1);
  c21=RD_0_E_x(1,2);c22=RD_0_E_x(2,2);c23=RD_0_E_x(3,2);
  c31=RD_0_E_x(1,3);c32=RD_0_E_x(2,3);c33=RD_0_E_x(3,3);
  dDPidRb1 = [c11 0 0 c21 0 0 c31 0 0; 0 c11 0 0 c21 0 0 c31 0; 0 0 c11 0 0 c21 0 0 c31; c12 0 0 c22 0 0 c32 0 0; 0 c12 0 0 c22 0 0 c32 0; 0 0 c12 0 0 c22 0 0 c32; c13 0 0 c23 0 0 c33 0 0; 0 c13 0 0 c23 0 0 c33 0; 0 0 c13 0 0 c23 0 0 c33;];
  %   dPidRbD1  is the differentiation of the second term found in the
  %   equation (34)
  
  % Term I aus Gl. (B.31): Ableitung der Euler-Winkel nach der Rot.-matrix
  % Euler-Winkel-Konvention von Trafo W->E
  % Aus codeexport/eulxyz_diff_rmatvec_matlab.m
  %R_0x_0qD = R_0x_0q * skew (omega) 
   dphidRb = eul_diff_rotmat(R_0x_0q, Rob.phiconv_W_E);
   % dphidRbD  is the ableitung von die zweite term
   %RD_0x_0q = RD_0_E_x * R_0_E_q+ R_0_E_x* RD_0_E_q ;
   dDphidRb =  eulD_diff_rotmat(R_0x_0q, RD_0x_0q, Rob.phiconv_W_E); 
  % Gl. (B.31)
  %Phi_phi_i_Gradq = dphidRb * dPidRb1 * dRb_0E_dq;
 
 %%   Phi_phi_i_GradDq is the differentiation of constr1grad_rq  with respect to time 
  PhiD_phi_i_Gradq = dphidRb * dDPidRb1 * dRb_0E_dq + ...  % A  * BD * C
                     dphidRb  * dPidRb1 * dDRb_0E_dq + ... % A  * B  * CD
                     dDphidRb * dPidRb1 * dRb_0E_dq;       % AD * B  * C

  % In Endergebnis einsetzen
  I1 = 1+3*(iLeg-1); % I: Zeilen der Ergebnisvariable: Alle rotatorischen ZB
  I2 = I1+2; % drei rotatorische Einträge
  J1 = Rob.I1J_LEG(iLeg); % J: Spalten der Ergebnisvariable: Alle Gelenke
  J2 = Rob.I2J_LEG(iLeg); % so viele Einträge wie Beine in der Kette
  Phipq(I1:I2,J1:J2) = PhiD_phi_i_Gradq;
  
  K2 = K1+sum(Rob.Leg(iLeg).I_EE(4:6))-1; % drei rotatorische Einträge
  Phipq_red(K1:K2,J1:J2) = PhiD_phi_i_Gradq(Rob.Leg(iLeg).I_EE(4:6),:);
  K1 = K2+1;
end
