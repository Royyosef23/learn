# Quick Start Guide - Terraform Infrastructure

## התחלה מהירה ב-5 דקות

### שלב 1: הכנת הקבצים
```bash
# כנס לתיקיית הטרהפורם
cd terraform

# העתק את קובץ הדוגמה
copy terraform.tfvars.example terraform.tfvars
# או בלינוקס/מק:
# cp terraform.tfvars.example terraform.tfvars
```

### שלב 2: ערוך את הערכים שלך
פתח את `terraform.tfvars` וערוך:
```hcl
location = "West Europe"  # או המיקום שאתה מעדיף

tags = {
  Environment = "Development"
  Project     = "WeatherAPI"
  Owner       = "השם שלך כאן"        # החלף!
  Email       = "email@example.com"    # החלף!
  Department  = "Engineering"
}
```

### שלב 3: אתחול וולידציה
```bash
# אתחול Terraform
terraform init

# בדיקת תחביר
terraform validate

# תצוגה מקדימה
terraform plan -var-file="terraform.tfvars"
```

### שלב 4: בניית התשתית
```bash
# בניה (ייקח 5-10 דקות)
terraform apply -var-file="terraform.tfvars"

# הקלד "yes" כשמתבקש
```

### שלב 5: קבלת פרטי התשתית
```bash
# פרטי ה-AKS
terraform output kubernetes_cluster_name
terraform output resource_group_name
terraform output acr_login_server

# שמור את הערכים האלה - תצטרך אותם לGitHub Secrets!
```

## אופציות התאמה מהירות

### 🌍 מיקומים מומלצים לישראל
```hcl
# מהיר ביותר (שורה אחת בלבד!)
location = "West Europe"      # אמסטרדם - הכי קרוב
# location = "East US"        # וירג'יניה - חלופה טובה
# location = "North Europe"   # אירלנד - גם קרוב
```

### 💰 חסכון בעלויות
```hcl
# שנה בmain.tf את גודל הVM:
vm_size = "Standard_B1s"      # במקום B2s - חוסך 50%
max_count = 2                 # במקום 3 - פחות nodes
```

### 🚀 ביצועים גבוהים
```hcl
# שנה בmain.tf לביצועים טובים יותר:
vm_size = "Standard_D2s_v3"   # במקום B2s - יותר כוח
min_count = 2                 # במקום 1 - תמיד 2 nodes
```

## פקודות שימושיות

### בדיקת מצב
```bash
terraform state list                    # רשימת משאבים
terraform show                          # מצב מלא
terraform output                        # כל הoutputs
```

### עדכון
```bash
terraform plan -var-file="terraform.tfvars"    # בדיקת שינויים
terraform apply -var-file="terraform.tfvars"   # יישום שינויים
```

### מחיקה
```bash
terraform destroy -var-file="terraform.tfvars"  # מחיקה מלאה
```

## טיפים חשובים

### ✅ לפני הרצה ראשונה
- [ ] ודא שאתה מחובר ל-Azure: `az login`
- [ ] בדוק את המנוי: `az account show`
- [ ] ערוך את terraform.tfvars עם הפרטים שלך
- [ ] הרץ `terraform plan` לפני `apply`

### ⚠️ זהירות!
- קובץ `terraform.tfvars` מכיל מידע אישי - לא לcommit לגיט!
- `terraform destroy` מוחק הכל - אין undo!
- השינויים ב-main.tf משפיעים על כל המשאבים

### 💡 טיפים
- השתמש ב-`terraform plan` תמיד לפני `apply`
- שמור backup של קובץ `.tfstate` 
- קרא את הoutput של `terraform apply` - יש שם מידע חשוב

## מה הלאה?

לאחר שהטרהפורם הסתיים בהצלחה:

1. **קבל את הפרטים**: `terraform output`
2. **עדכן GitHub Secrets** עם הערכים שקיבלת
3. **המשך לשלב הבא** במדריך הראשי (README.md)

זהו! התשתית שלך מוכנה! 🎉
