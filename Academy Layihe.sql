-- =====================================================================
-- "HANDEX ACADEMY" ONLAYN KURS PLATFORMASI
-- =====================================================================
--  HEKAYƏ:
--  "Handex Academy" onlayn kurs platformasıdır. 3 il əvvəl 2 müəllim və
--  bir neçə kursla başlayıb, indi 8 müəllimi və 20 kursu var. Platforma
--  sürətlə böyüyür, amma investorlar növbəti mərhələ üçün real rəqəmlər
--  istəyir: kim qazandırır, kim borcludur, hansı kurs ölüdür?
--
--  Sən platformanın ilk data analitikisən. Baş direktor sənə deyir:
--  "Mənə gözəl slaydlar lazım deyil. Hər sualıma cədvəllər ilə cavab ver."
--
--  DİQQƏT (məlumatın xüsusiyyətləri):
--   - Bir qeydiyyatın (enrollment) BİR NEÇƏ ödənişi ola bilər (hissə-hissə).
--   - Bəzi qeydiyyatların heç bir ödənişi yoxdur (borclu tələbələr).
--   - Bəzi tələbələr heç bir kursa yazılmayıb.
--   - Bəzi kurslar ARCHIVED statusdadır, bəzilərinin heç qeydiyyatı yoxdur.


--  CƏDVƏL STRUKTURU
--
--   +--------------------+                      +----------------------+
--   |      CATEGORY      |                      |      INSTRUCTOR      |
--   +--------------------+                      +----------------------+
--   | PK category_id     |                      | PK instructor_id     |
--   |    category_name   |                      |    first_name        |
--   |    category_desc.. |                      |    last_name         |
--   +--------------------+                      |    hire_date         |
--             |1                                |    country           |
--             |                                 |    status            |
--             |                                 +----------------------+
--             |                                            |1
--             |            +--------------------+          |
--             +----N------>|       COURSE       |<----N----+
--                          +--------------------+
--                          | PK course_id       |
--                          |    course_title    |
--                          | FK category_id     |
--                          | FK instructor_id   |
--                          |    price           |
--                          |    course_level    |
--                          |    duration_hours  |
--                          |    publish_date    |
--                          |    status          |
--                          +--------------------+
--                                     |1
--                                     |
--   +--------------------+            |N
--   |      STUDENT       |   +------------------------+
--   +--------------------+   |       ENROLLMENT       |
--   | PK student_id      |   +------------------------+
--   |    first_name      |1  | PK enrollment_id       |
--   |    last_name       |---| FK student_id          |
--   |    birth_date      | N | FK course_id           |
--   |    register_date   |   |    enroll_date         |
--   |    city            |   |    progress_percent    |
--   |    status          |   |    status              |
--   +--------------------+   |    completion_date     |
--                            +------------------------+
--                                 |1              |1
--                     +-----------+               +-----------+
--                     |N                                     |N
--          +----------------------+            +----------------------+
--          |       PAYMENT        |            |        REVIEW        |
--          +----------------------+            +----------------------+
--          | PK payment_id        |            | PK review_id         |
--          | FK enrollment_id     |            | FK enrollment_id     |
--          |    payment_date      |            |    review_date       |
--          |    amount            |            |    rating  (1-5)     |
--          |    payment_method    |            +----------------------+
--          +----------------------+
--
--
--  ƏLAQƏLƏR (kardinallıq)
--  ---------------------------------------------------------------------
--   category    1 : N  course        bir kateqoriyada çox kurs
--   instructor  1 : N  course        bir müəllimin çox kursu
--   student     1 : N  enrollment    bir tələbə çox kursa yazıla bilər
--   course      1 : N  enrollment    bir kursa çox tələbə yazıla bilər
--   enrollment  1 : N  payment       BİR QEYDİYYATIN BİR NEÇƏ ÖDƏNİŞİ OLA BİLƏR
--   enrollment  1 : N  review        bir qeydiyyata rəy yazıla bilər (0 və ya 1)
--
--  status dəyərləri:
--     course.status      -> 'ACTIVE' | 'ARCHIVED'
--     enrollment.status  -> 'ACTIVE' | 'COMPLETED' | 'CANCELLED'
--     instructor.status  -> 'ACTIVE' | 'PASSIVE'
--     student.status     -> 'ACTIVE' | 'PASSIVE'
--     payment_method     -> 'CARD'   | 'CASH'      | 'TRANSFER'   | 'INSTALLMENT'


-- =====================================================================
--  ÜMUMİ QAYDALAR
-- =====================================================================
-- * Ay sütunu istənilən suallarda to_char(<tarix>, 'YYYY-MM') formatında və
--   month_text adı ilə qaytarılmalıdır.
-- * Tarix suallarında sysdate-ə nisbətdə yazılmalıdır. Məsələn:
--       son 3 ay -> add_months(trunc(sysdate), -3)
--       son 6 ay -> add_months(trunc(sysdate), -6)
--       son 1 il -> add_months(trunc(sysdate), -12)
--   Tarixlər HEÇ VAXT əl ilə ('01.01.2026' kimi) yazılmamalıdır.
-- * Gəlir həmişə payment.amount üzərindən hesablanır (course.price yox).
-- * Pul və faiz sütunları 2 onluq işarə ilə yuvarlaqlaşdırılmalıdır (round).
-- * Nəticə sütunlarının adları və sırası tapşırıqda göstərildiyi kimi olmalıdır.
-- =====================================================================


-- 1. KATALOQUN VƏZİYYƏTİ
-- Direktor investor görüşünə hazırlaşır: "Hər kateqoriyada neçə AKTİV
-- kursumuz var və orta qiymət nə qədərdir? Bütün kateqoriyalar siyahıda
-- qalsın, aktiv kursu olmayan kateqoriya da görünsün."
-- Sıralama: kurs sayı azalan.
-- Nəticə: category_id, category_name, course_count, avg_price

select
    c.category_id,
    c.category_name,
    count(co.course_id)      as course_count,
    ROUND(avg(co.price), 2)  as avg_price
from category c
left join course co on co.category_id = c.category_id
      and co.status = 'ACTIVE'
group by c.category_id, c.category_name
order by course_count desc;


-- 2. PUL AXINI
-- Maliyyə direktoru qrafik çəkmək istəyir: "Son 12 ayda hər ay neçə ödəniş
-- daxil olub və ümumi məbləğ nə qədərdir? Aylar artan sırada."
-- Nəticə: month_text, payment_count, total_amount

select
    to_char(p.payment_date,'YYYY-MM') as month_text,
    count(*) as payment_count,
    round(sum(p.amount), 2) as total_amount
from payment p
where p.payment_date >= add_months(trunc(sysdate), -12)
group by to_char(p.payment_date, 'YYYY-MM')
order by month_text;


-- 3. MÜƏLLİMLƏRİN REYTİNQİ (PUL İLƏ)
-- Direktor müəllimlərin bonusunu hesablayır: "Hər müəllimin neçə kursu var
-- və onun kursları platformaya ümumilikdə nə qədər pul gətirib? BÜTÜN
-- müəllimlər siyahıda olsun yeni işə götürdüyümüz, hələ kursu olmayan
-- müəllim də 0 ilə görünsün."
-- Sıralama: gəlir azalan.
-- Nəticə: instructor_id, first_name, last_name, course_count, total_revenue

select
    i.instructor_id,
    i.first_name,
    i.last_name,
    count(distinct co.course_id)      as course_count,
    round(nvl(sum(pay.amount), 0), 2) as total_revenue
from instructor i
left join course co     on co.instructor_id = i.instructor_id
left join enrollment e  on e.course_id = co.course_id
left join payment pay   on pay.enrollment_id = e.enrollment_id
group by i.instructor_id, i.first_name, i.last_name
order by total_revenue desc;


-- 4. ÖLÜ KURSLAR
-- Məhsul meneceri: "Elə kurslar var ki, sayta qoymuşuq, amma bir nəfər də
-- yazılmayıb. Onları kataloqdan çıxarmaq istəyirəm, siyahını ver."
-- Nəticə: course_id, course_title, category_name, price

select
    co.course_id,
    co.course_title,
    ca.category_name,
    co.price
from course co
join category ca on ca.category_id = co.category_id
where not exists (
    select 1
    from enrollment e
    where e.course_id = co.course_id
);



-- 5. TAMAMLANMA PROBLEMİ
-- Direktor narahatdır: "Tələbələr kursları bitirmir. Ən azı 3 qeydiyyatı
-- olan hər kurs üçün qeydiyyat sayını, tamamlayanların sayını və
-- tamamlanma faizini göstər. Ləğv edilmiş (CANCELLED) qeydiyyatlar
-- ümumiyyətlə sayılmasın."
-- completion_rate = tamamlayan / ümumi * 100
-- Sıralama: faiz azalan.
-- Nəticə: course_id, course_title, enrollment_count, completed_count, completion_rate

select
    co.course_id,
    co.course_title,
    count(*)  as enrollment_count,
    count(case when e.status = 'COMPLETED' then 1 end) as completed_count,
    round(
        count(case when e.status = 'COMPLETED' then 1 end) * 100  / count(*) , 2)                                                         as completion_rate
from enrollment e
join course co on co.course_id = e.course_id
where e.status != 'CANCELLED'
group by co.course_id, co.course_title
having count(*) >= 3
order by completion_rate desc;




-- 6. BORCLULAR (I HİSSƏ)
-- Mühasibat şöbəsi zəng edir: "Elə qeydiyyatlar var ki, tələbə kursa
-- yazılıb, amma heç bir ödəniş etməyib. Kimlərdir?"
-- Nəticə: enrollment_id, student_id, first_name, last_name, course_title,
--         enroll_date, price
select
    e.enrollment_id,
    e.student_id,
    s.first_name,
    s.last_name,
    co.course_title,
    e.enroll_date,
    co.price
from enrollment e
join student s on s.student_id = e.student_id
join course co on co.course_id = e.course_id
where not exists (
    select 1
    from payment p
    where p.enrollment_id = e.enrollment_id
);

-- 7. BORCLULAR (II HİSSƏ)
-- Mühasib davam edir: "İndi də hissə-hissə ödəyib yarımçıq qoyanları tap.
-- Yəni ödədiyi ümumi məbləğ kursun qiymətindən azdır."
-- Sıralama: borc azalan.
-- Nəticə: enrollment_id, student_id, course_title, price, paid_amount, debt

select
    e.enrollment_id,
    e.student_id,
    co.course_title,
    co.price,
    round(sum(p.amount), 2) as paid_amount,
    round(co.price - sum(p.amount), 2) as debt
from enrollment e
join course co  on co.course_id = e.course_id
join payment p  on p.enrollment_id = e.enrollment_id
group by e.enrollment_id, e.student_id, co.course_title, co.price
having sum(p.amount) < co.price
order by debt desc;



-- 8. ƏN BÖYÜK ÖDƏNİŞLƏR
-- Marketinq şöbəsi VIP kampaniya hazırlayır: "Hər tələbənin son 1 ildə
-- etdiyi ən böyük ödənişi göstər - tələbə başına yalnız 1 sətir olsun."
-- Bərabərlik: eyni məbləğ varsa tarixi daha yeni olan seçilsin.
-- Sıralama: məbləğ azalan.
-- Nəticə: student_id, first_name, last_name, payment_id, payment_date, amount

select
    student_id,
    first_name,
    last_name,
    payment_id,
    payment_date,
    amount
from (
    select
        e.student_id,
        s.first_name,
        s.last_name,
        p.payment_id,
        p.payment_date,
        p.amount,
        row_number() over (
            partition by e.student_id
            order by p.amount desc, p.payment_date desc
        ) as rn
    from payment p
    join enrollment e on e.enrollment_id = p.enrollment_id
    join student s    on s.student_id = e.student_id
    where p.payment_date >= add_months(trunc(sysdate), -12)
)
where rn = 1
order by amount desc;



-- 9. HƏR KATEQORİYANIN LOKOMOTİVİ
-- Direktor reklam büdcəsini bölür: "Hər kateqoriyada ən çox pul gətirən
-- kursu göstər - kateqoriya başına 1 sətir."
-- Bərabərlik: eyni məbləğ varsa course_id kiçik olan seçilsin.
-- Sıralama: gəlir azalan.
-- Nəticə: category_id, category_name, course_id, course_title, total_revenue

select
    category_id,
    category_name,
    course_id,
    course_title,
    total_revenue
from (
    select
        ca.category_id,
        ca.category_name,
        co.course_id,
        co.course_title,
        round(sum(p.amount), 2) as total_revenue,
        row_number() over (
            partition by ca.category_id
            order by sum(p.amount) desc, co.course_id asc
        ) as rn
    from category ca
    join course co     on co.category_id = ca.category_id
    join enrollment e  on e.course_id = co.course_id
    join payment p     on p.enrollment_id = e.enrollment_id
    group by ca.category_id, ca.category_name, co.course_id, co.course_title
)
where rn = 1
order by total_revenue desc;



-- 10. ƏN SADİQ TƏLƏBƏ
-- CRM komandası hədiyyə göndərmək istəyir: "Ən çox kursa yazılmış tələbəni
-- tap. Eyni sayda kursu olan bir neçə tələbə varsa hamısı göstərilsin."
-- Nəticə: student_id, first_name, last_name, enrollment_count

select
    student_id,
    first_name,
    last_name,
    enrollment_count
from (
    select
        s.student_id,
        s.first_name,
        s.last_name,
        count(*) as enrollment_count,
        rank() over (order by count(*) desc) as rnk
    from student s
    join enrollment e on e.student_id = s.student_id
    group by s.student_id, s.first_name, s.last_name
)
where rnk = 1;



-- 11. AYIN BESTSELLERİ
-- Marketinq şöbəsi aylıq hesabat hazırlayır: "Son 6 ayda hər ay ən çox
-- qeydiyyat alan kursu göstər - hər ay üçün 1 sətir."
-- Bərabərlik: eyni sayda qeydiyyat varsa course_id kiçik olanı götür.
-- Sıralama: ay artan.
-- Nəticə: month_text, course_id, course_title, enrollment_count

select
    month_text,
    course_id,
    course_title,
    enrollment_count
from (
    select
        to_char(e.enroll_date, 'YYYY-MM') as month_text,
        co.course_id,
        co.course_title,
        count(*) as enrollment_count,
        row_number() over (
            partition by to_char(e.enroll_date, 'YYYY-MM')
            order by count(*) desc, co.course_id asc
        ) as rn
    from enrollment e
    join course co on co.course_id = e.course_id
    where e.enroll_date >= add_months(trunc(sysdate), -6)
    group by to_char(e.enroll_date, 'YYYY-MM'), co.course_id, co.course_title
)
where rn = 1
order by month_text;



-- 12. RƏYLƏR
-- Məhsul meneceri sayta "Ən yaxşı kurslar" bölməsi əlavə edir: "Ən azı 3
-- rəyi olan kursların orta reytinqini göstər."
-- Sıralama: orta reytinq azalan, sonra rəy sayı azalan.
-- Nəticə: course_id, course_title, review_count, avg_rating

select
    co.course_id,
    co.course_title,
    count(*)               as review_count,
    round(avg(r.rating), 2) as avg_rating
from course co
join enrollment e on e.course_id = co.course_id
join review r     on r.enrollment_id = e.enrollment_id
group by co.course_id, co.course_title
having count(*) >= 3
order by avg_rating desc, review_count desc;

-- 13. ORTADAN YUXARI
-- Direktor: "Mənə platformanın ümumi orta reytinqindən yüksək olan
-- kursları göstər. Ümumi ortanı əl ilə yazma, sorğunun içində hesabla."
-- Sıralama: orta reytinq azalan.
-- Nəticə: course_id, course_title, avg_rating

select
    co.course_id,
    co.course_title,
    round(avg(r.rating), 2) as avg_rating
from course co
join enrollment e on e.course_id = co.course_id
join review r     on r.enrollment_id = e.enrollment_id
group by co.course_id, co.course_title
having avg(r.rating) > (select avg(rating) from review)
order by avg_rating desc;

-- 14. AUDİTORİYA PORTRETİ
-- Marketinq şöbəsi reklam hədəfini dəqiqləşdirir: "Tələbələri yaş qruplarına
-- böl və hər qrupda neçə tələbə olduğunu, həmçinin orta ödəniş məbləğini
-- göstər. Heç ödəniş etməmiş tələbə də qrupda sayılsın (0 ilə)."
-- Yaş qrupları: '25 və aşağı', '26-35', '36 və yuxarı'
-- Nəticə: age_group, student_count, avg_paid

with student_paid as (
    select
        s.student_id,
        s.birth_date,
        nvl(sum(p.amount), 0) as total_paid
    from student s
    left join enrollment e on e.student_id = s.student_id
    left join payment p    on p.enrollment_id = e.enrollment_id
    group by s.student_id, s.birth_date
),
student_age as (
    select
        student_id,
        total_paid,
        trunc(months_between(sysdate, birth_date) / 12) as age
    from student_paid
)
select
    case
        when age <= 25 then '25 və aşağı'
        when age between 26 and 35 then '26-35'
        else '36 və yuxarı'
    end as age_group,
    count(*)                as student_count,
    round(avg(total_paid), 2) as avg_paid
from student_age
group by
    case
        when age <= 25 then '25 və aşağı'
        when age between 26 and 35 then '26-35'
        else '36 və yuxarı'
    end;


-- 15. YUXUYA GEDƏNLƏR
-- Satış komandası zəng siyahısı istəyir: "Aktiv qeydiyyatı olan, amma son
-- 3 ayda HEÇ BİR ödəniş etməmiş tələbələri tap."
-- Nəticə: student_id, first_name, last_name, active_enrollment_count

select
    s.student_id,
    s.first_name,
    s.last_name,
    count(*) as active_enrollment_count
from student s
join enrollment e on e.student_id = s.student_id
where e.status = 'ACTIVE'
  and not exists (
        select 1
        from enrollment e2
        join payment p2 on p2.enrollment_id = e2.enrollment_id
        where e2.student_id = s.student_id
          and p2.payment_date >= add_months(trunc(sysdate), -3)
      )
group by s.student_id, s.first_name, s.last_name;


-- 16. MÜƏLLİMİN ƏN YAXŞI KURSU
-- İl sonu mükafatı üçün: "Hər müəllimin ən yüksək orta reytinqli kursunu
-- göstər - müəllim başına 1 sətir. Heç rəyi olmayan müəllim siyahıda
-- olmaya bilər."
-- Bərabərlik: eyni orta reytinq varsa rəy sayı çox olan kurs seçilsin.
-- Sıralama: orta reytinq azalan.
-- Nəticə: instructor_id, first_name, last_name, course_id, course_title,
--         avg_rating, review_count

select
    instructor_id,
    first_name,
    last_name,
    course_id,
    course_title,
    avg_rating,
    review_count
from (
    select
        i.instructor_id,
        i.first_name,
        i.last_name,
        co.course_id,
        co.course_title,
        round(avg(r.rating)
--yazanmadim

commit
