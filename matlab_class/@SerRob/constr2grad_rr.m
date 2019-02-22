% Ableitung der Rotationskomponente der kinematischen Zwangsbedingungen
% nach der EE-Orientierung
% Variante 2:
% * Absolute Rotation ausgedrückt z.B. in XYZ-Euler-Winkeln
% * Rotationsfehler ausgedrückt in Euler-Winkeln (um raumfeste Achsen), je
%   nach Eingabeargument `reci` (entspricht teilweise PKM-Variante 2)
% 
% Eingabe:
% q
%   Gelenkkoordinaten des Roboters
% xE
%   Endeffektorpose des Roboters bezüglich des Basis-KS
% reci (Optional)
%   true: Nehme reziproke Euler-Winkel für Orientierungsfehler (z.B.
%   ZYX-Orientierungsfehler für XYZ-Absolutorientierung)
%   false: Gleiche Euler-Winkel für Fehler und Absolut [Standard]
% 
% Ausgabe:
% Phi_rr [3x3]
%   Matrix mit Ableitungen der 3 rotatorischen Zwangsbedingungskomponenten
%   (in den Zeilen) nach den 3 EE-Rotationskoordinaten (in den Spalten)
% 
% Siehe auch: ParRob/constr1grad_rr

% Quellen:
% [A] Aufzeichnungen Schappler vom 19.06.2018
% [B] Aufzeichnungen Schappler vom 21.06.2018
% [C] Aufzeichnungen Schappler vom 13.07.2018

% Moritz Schappler, moritz.schappler@imes.uni-hannover.de, 2019-01
% (C) Institut für Mechatronische Systeme, Universität Hannover

function Phi_rr = constr2grad_rr(Rob, q, xE, reci)

assert(isreal(q) && all(size(q) == [Rob.NJ 1]), ...
  'SerRob/constr2grad_rr: q muss %dx1 sein', Rob.NJ);
if nargin < 4
  reci = false;
end
% Endergebnis, siehe Gl. (B.30)

R_0_E_x = eul2r(xE(4:6), Rob.phiconv_W_E);
if reci
  [~,phiconv_delta] = euler_angle_properties(Rob.phiconv_W_E);
else
  phiconv_delta = Rob.phiconv_W_E;
end


% Kinematik, Definitionen
T_0_E = Rob.fkineEE(q);
R_0_E_q = T_0_E(1:3,1:3);

% Rotationsmatrix Differenz-Rotation. So Definiert wie in den
% Zwangsbedingungen bsp6uPs_ZB_phi
R_Ex_Eq = R_0_E_x' * R_0_E_q;

% Dritter Termin in Gl. (C.35): Ableitung des Matrixproduktes
% Gl. (B.12)
% Unabhängig vom Roboter (Rotationsmatrix aus Kinematik wird in
% Platzhalterelemente eingesetzt)
% Aus rmatvecprod_diff_rmatvec2_matlab.m
a11=R_0_E_q(1,1);a21=R_0_E_q(1,2);a31=R_0_E_q(1,3);
a12=R_0_E_q(2,1);a22=R_0_E_q(2,2);a32=R_0_E_q(2,3);
a13=R_0_E_q(3,1);a23=R_0_E_q(3,2);a33=R_0_E_q(3,3);
dPidR1b = [a11 a12 a13 0 0 0 0 0 0; a21 a22 a23 0 0 0 0 0 0; a31 a32 a33 0 0 0 0 0 0; 0 0 0 a11 a12 a13 0 0 0; 0 0 0 a21 a22 a23 0 0 0; 0 0 0 a31 a32 a33 0 0 0; 0 0 0 0 0 0 a11 a12 a13; 0 0 0 0 0 0 a21 a22 a23; 0 0 0 0 0 0 a31 a32 a33;];

% vierter Termin in Gl. (B.35): Ableitung von R_0_E nach den Euler-Winkeln
% Unabhängig vom Roboter (nur von Orientierungsdarstellung)
dR0Ebdphi = rotmat_diff_eul(xE(4:6), Rob.phiconv_W_E);

% Transpositions-Matrix; Gl (C.29)
% zweiter Term in Gl. (B.35)
% Aus permat_rvec_transpose_matlab.m
P_T = [1 0 0 0 0 0 0 0 0; 0 0 0 1 0 0 0 0 0; 0 0 0 0 0 0 1 0 0; 0 1 0 0 0 0 0 0 0; 0 0 0 0 1 0 0 0 0; 0 0 0 0 0 0 0 1 0; 0 0 1 0 0 0 0 0 0; 0 0 0 0 0 1 0 0 0; 0 0 0 0 0 0 0 0 1;];

% Erster Term in Gl. (C.35),(C.28),(B.16): Ableitung der Euler-Winkel nach der
% Rotationsmatrix
% Aus P_3RRR/phixyz_diff_rmatvec_matlab.m
% Unabhängig vom Roboter (nur von Orientierungsdarstellung)
dphidRb = eul_diff_rotmat(R_Ex_Eq, phiconv_delta);

% Gl. (C.35)
Phi_rr = dphidRb * P_T*dPidR1b * dR0Ebdphi;