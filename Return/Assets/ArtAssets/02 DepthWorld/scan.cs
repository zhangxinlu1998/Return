using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class scan : MonoBehaviour {
    // Start is called before the first frame update
    //Transform target ;
    //public GameObject target;
    public Material mat;
    void Start () {
        //mat = target.GetComponentInChildren<MeshRenderer> ().sharedMaterial;
    }

    // Update is called once per frame
    void Update () {

        if (Input.GetMouseButtonDown (0)) {
            Ray ray = Camera.main.ScreenPointToRay (Input.mousePosition);

            RaycastHit hit;

            if (Physics.Raycast (ray, out hit)) {
                StopAllCoroutines ();
                StartCoroutine (Hit (3f, hit));          
            }

        }
    }

    IEnumerator Hit (float time, RaycastHit hit) {
        float _time = 0;
        float dis = 1;
        Vector3 v = hit.point;
        mat.SetVector ("_ScanPosition", v);

        while (true) {
            _time += Time.deltaTime ;
            dis -= Time.deltaTime*1.5f ;
            float speed = mat.GetFloat ("_Speed");
            yield return new WaitForEndOfFrame ();

            if (_time > time) {
                mat.SetFloat ("_time", 0);
                mat.SetFloat ("_SpeedRange", 0);
                mat.SetFloat ("_Disappear", 1);
                yield break;

            } else {
                mat.SetFloat ("_time", _time / time);
                mat.SetFloat ("_SpeedRange",  _time / time);
                mat.SetFloat ("_Disappear", dis);
            }
        }

    }

}