% Calculate Gravitation load on the joints for
% rigidbody
% Use Code from Maple symbolic Code Generation
% 
% Input:
% phi_base [3x1]
%   Base orientation in world frame. Expressed with XYZ-Euler angles
% g [3x1]
%   gravitation vector in world frame [m/s^2]
% m_mdh [1x1]
%   mass of all robot links (including the base)
% mrSges [1x3]
%  first moment of all robot links (mass times center of mass in body frames)
%  rows: links of the robot (starting with base)
%  columns: x-, y-, z-coordinates
% 
% Output:
% taug [6x1]
%   base forces required to compensate gravitation load

% Quelle: HybrDyn-Toolbox
% Datum: 2019-03-19 12:00
% Revision: 3380762d7a67e58abcb72423f3b6cbd7db453188 (2019-03-19)
% Moritz Schappler, moritz.schappler@imes.uni-hannover.de
% (C) Institut für Mechatronische Systeme, Universität Hannover

function taug = rigidbody_gravloadB_floatb_eulxyz_slag_vp2(phi_base, g, ...
  m, mrSges)
%% Coder Information
%#codegen
%$cgargs {zeros(3,1),zeros(3,1),zeros(1,1),zeros(1,3)}
assert(isreal(phi_base) && all(size(phi_base) == [3 1]), ...
  'rigidbody_gravloadB_floatb_eulxyz_slag_vp2: phi_base has to be [3x1] (double)');
assert(isreal(m) && all(size(m) == [1 1]), ...
  'rigidbody_gravloadB_floatb_eulxyz_slag_vp2: m has to be [1x1] (double)'); 
assert(isreal(mrSges) && all(size(mrSges) == [1,3]), ...
  'rigidbody_gravloadB_floatb_eulxyz_slag_vp2: mrSges has to be [1x3] (double)');

%% Symbolic Calculation
% From gravload_base_floatb_eulxyz_par2_matlab.m
% OptimizationMode: 2
% StartTime: 2019-03-19 12:00:19
% EndTime: 2019-03-19 12:00:19
% DurationCPUTime: 0.10s
% Computational Cost: add. (29->22), mult. (72->41), div. (0->0), fcn. (69->6), ass. (0->15)
t6 = sin(phi_base(1));
t9 = sin(phi_base(2));
t15 = t6 * t9;
t8 = cos(phi_base(1));
t14 = t8 * t9;
t10 = cos(phi_base(2));
t12 = t10 * mrSges(1,3);
t5 = sin(phi_base(3));
t7 = cos(phi_base(3));
t11 = mrSges(1,1) * t7 - mrSges(1,2) * t5;
t4 = t7 * t14 - t5 * t6;
t3 = t5 * t14 + t6 * t7;
t2 = t7 * t15 + t5 * t8;
t1 = -t5 * t15 + t7 * t8;
t13 = [-g(1) * m(1), -g(2) * m(1), -g(3) * m(1), -g(2) * (t4 * mrSges(1,1) - t3 * mrSges(1,2) - t8 * t12) - g(3) * (t2 * mrSges(1,1) + t1 * mrSges(1,2) - t6 * t12) -g(1) * (-t11 * t9 + t12) + (-g(2) * t6 + g(3) * t8) * (mrSges(1,3) * t9 + t11 * t10) -g(2) * (mrSges(1,1) * t1 - mrSges(1,2) * t2) - g(3) * (mrSges(1,1) * t3 + mrSges(1,2) * t4) - g(1) * (-mrSges(1,1) * t5 - mrSges(1,2) * t7) * t10];
taug  = t13(:);
